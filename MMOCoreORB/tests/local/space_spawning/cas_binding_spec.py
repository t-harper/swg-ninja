#!/usr/bin/env python3
"""Compile the real Director Lua CAS method against boundary-only doubles.

No engine binary, game database, or network is opened. The extracted production
method (not a reimplementation) races 32 threads against one shared-memory key.
"""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[3]
source = (root / 'src/server/zone/managers/director/DirectorManager.cpp').read_text()
signature = 'int DirectorManager::compareAndSetSharedMemory(lua_State* L)'
assert signature in source, 'Production atomic shared-memory binding is missing'
start = source.index(signature)
brace = source.index('{', start)
depth, end = 1, brace + 1
while depth:
    depth += (source[end] == '{') - (source[end] == '}')
    end += 1
method = source[start:end]
prefix = r'''
#include <atomic>
#include <cassert>
#include <cstdint>
#include <iostream>
#include <map>
#include <mutex>
#include <string>
#include <thread>
#include <vector>
using String = std::string;
using uint64 = std::uint64_t;
struct lua_State { String key; long long expected; long long desired; int argc=3; bool result=false; };
const char* lua_tostring(lua_State* l,int) {return l->key.c_str();}
long long lua_tointeger(lua_State* l,int i) {return i==-2?l->expected:l->desired;}
void lua_pushboolean(lua_State* l,bool value) {l->result=value;}
struct Memory {
 std::map<String,uint64> values;
 uint64 get(const String& key) {std::this_thread::yield();return values[key];}
 void put(const String& key,uint64 value) {std::this_thread::yield();values[key]=value;}
};
class DirectorManager {
 std::mutex mutex;
public:
 Memory store; Memory* sharedMemory=&store;
 static int ERROR_CODE; enum {INCORRECT_ARGUMENTS=1};
 static DirectorManager* instance(){static DirectorManager value;return &value;}
 static int checkArgumentCount(lua_State* l,int n){return l->argc==n?0:1;}
 static void printTraceError(lua_State*,const String&){}
 void lock(){mutex.lock();} void unlock(){mutex.unlock();}
 static int compareAndSetSharedMemory(lua_State*);
};
int DirectorManager::ERROR_CODE=0;
struct Locker {DirectorManager* lock;explicit Locker(DirectorManager* value):lock(value){lock->lock();}~Locker(){lock->unlock();}};
'''
suffix = r'''
int main(){
 auto* director=DirectorManager::instance();
 for(int round=0;round<100;++round){
  director->store.values["cohort"]=1;
  std::atomic<int> successes{0};std::vector<std::thread> workers;
  for(int n=0;n<32;++n)workers.emplace_back([&]{lua_State state{"cohort",1,2};assert(DirectorManager::compareAndSetSharedMemory(&state)==1);if(state.result)++successes;});
  for(auto& worker:workers)worker.join();
  assert(successes==1);assert(director->store.values["cohort"]==2);
 }
 lua_State mismatch{"cohort",1,0};DirectorManager::compareAndSetSharedMemory(&mismatch);assert(!mismatch.result);assert(director->store.values["cohort"]==2);
 lua_State missing{"absent",1,2};DirectorManager::compareAndSetSharedMemory(&missing);assert(!missing.result);
 lua_State invalid{"cohort",2,0,2};assert(DirectorManager::compareAndSetSharedMemory(&invalid)==0);assert(DirectorManager::ERROR_CODE==1);assert(director->store.values["cohort"]==2);
 std::cout<<"PASS real C++ CAS binding: 100 rounds of 32 concurrent claims, mismatch, missing key, invalid arity\n";
}
'''
with tempfile.TemporaryDirectory(prefix='swg-cas-') as temporary:
    path = Path(temporary)
    (path / 'binding.cpp').write_text(prefix + method + suffix)
    subprocess.run(['g++', '-std=c++17', '-O2', '-pthread', str(path / 'binding.cpp'), '-o', str(path / 'binding')], check=True)
    subprocess.run([str(path / 'binding')], check=True)
