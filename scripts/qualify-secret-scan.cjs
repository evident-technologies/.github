// Synthetic qualification of the exact inline scanner; no real credentials.
'use strict';
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const {spawnSync} = require('node:child_process');
const assert = require('node:assert/strict');
const yaml = fs.readFileSync(path.join(__dirname, '../.github/workflows/security-secret-scan.yml'), 'utf8');
const start = "          node <<'NODE'\n";
assert.equal(yaml.split(start).length, 2);
const source = yaml.split(start)[1].split('\n          NODE')[0].split('\n').map(s => s.slice(10)).join('\n');
const root = fs.mkdtempSync(path.join(os.tmpdir(), 'synthetic-scanner-'));
const scanner = path.join(root, 'scanner.cjs');
fs.writeFileSync(scanner, source);
const results = [];
const env = {...process.env, GIT_CONFIG_NOSYSTEM:'1', GIT_CONFIG_GLOBAL:'/dev/null',
  GIT_AUTHOR_NAME:'Synthetic', GIT_AUTHOR_EMAIL:'synthetic@example.invalid',
  GIT_COMMITTER_NAME:'Synthetic', GIT_COMMITTER_EMAIL:'synthetic@example.invalid'};
function git(repo, ...args) {
  const r=spawnSync('git', ['-C',repo,...args], {env,encoding:'utf8',timeout:10000});
  assert.equal(r.status,0,'synthetic Git operation failed');
  return r.stdout.trim();
}
function fixture() {
  const repo=fs.mkdtempSync(path.join(root,'case-'));
  git(repo,'init','-q'); git(repo,'config','commit.gpgsign','false');
  fs.writeFileSync(path.join(repo,'base.txt'),'Synthetic public baseline\n');
  return {repo,base:commit(repo)};
}
function commit(repo) {git(repo,'add','--all');git(repo,'commit','-qm','Synthetic fixture');return git(repo,'rev-parse','HEAD');}
function run(repo,base,head,extra={}) {
  const r=spawnSync(process.execPath,[scanner],{cwd:repo,env:{...env,DIFF_RANGE:base+'..'+head,SCAN_SCRIPT:'',...extra},
    encoding:'utf8',timeout:20000,maxBuffer:1024*1024});
  return {code:r.status,output:(r.stdout||'')+(r.stderr||''),error:r.error};
}
function check(name,r,blocked,marker) {
  assert.ok(!r.error,name+' scanner process failure');
  assert.equal(r.code!==0,blocked,name+' unexpected result');
  if(marker)assert.ok(!r.output.includes(marker),name+' unredacted diagnostic');
  results.push({case:name,result:blocked?'EXPECTED_BLOCK':'EXPECTED_ALLOW',pass:true});
}
const token='ghp_'+'A'.repeat(36);
try {
  for(const [name,file,value] of [
    ['clean','public.txt','Synthetic public software documentation'],
    ['source credential','source.js',token],
    ['compiled bundle','dist.js',token],
    ['served JSON','public.json',JSON.stringify({token})],
    ['binary ASCII credential','binary.dat','\0'+token+'\0'],
    ['unusual filename',' leading\n[*].txt',token]
  ]) {
    const {repo,base}=fixture();fs.writeFileSync(path.join(repo,file),value);
    check(name,run(repo,base,commit(repo)),name!=='clean',token);
  }
  {
    const {repo}=fixture();fs.writeFileSync(path.join(repo,'old.txt'),'safe\n'.repeat(150));
    const base=commit(repo);fs.renameSync(path.join(repo,'old.txt'),path.join(repo,'new.txt'));
    fs.appendFileSync(path.join(repo,'new.txt'),token);
    check('renamed disclosure',run(repo,base,commit(repo)),true,token);
  }
  {
    const {repo,base}=fixture();fs.writeFileSync(path.join(repo,'transient.txt'),token);commit(repo);
    fs.unlinkSync(path.join(repo,'transient.txt'));fs.writeFileSync(path.join(repo,'safe.txt'),'safe');
    check('intermediate disclosure',run(repo,base,commit(repo)),true,token);
  }
  {
    const {repo,base}=fixture();fs.writeFileSync(path.join(repo,'safe.txt'),'safe');const head=commit(repo);
    check('invalid range',run(repo,'invalid',head),true);
    check('missing dependency',run(repo,base,head,{PATH:'/missing'}),true);
    check('missing custom scanner',run(repo,base,head,{SCAN_SCRIPT:path.join(repo,'missing.cjs')}),true);
    const custom=path.join(repo,'custom.cjs');const marker='SYNTHETIC_PRIVATE_DIAGNOSTIC';
    fs.writeFileSync(custom,"throw new Error('"+marker+"')");
    check('custom crash redaction',run(repo,base,head,{SCAN_SCRIPT:custom}),true,marker);
    fs.writeFileSync(custom,"console.log('"+marker+"')");
    check('custom success redaction',run(repo,base,head,{SCAN_SCRIPT:custom}),false,marker);
    check('root clean',run(repo,'ROOT',head),false);
  }
  console.log(JSON.stringify({qualification:'exact inline scanner synthetic fixtures',cases:results.length,results}));
} catch {
  console.error('Synthetic scanner qualification failed; fixture values withheld.');
  process.exitCode=1;
} finally {fs.rmSync(root,{recursive:true,force:true});}
