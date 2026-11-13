# Recovered original 38-case behavior matrix, SHA-256 dd57745bcf3fa516a0b052793b6ba6a8f3aca8be31fc9ba72756a16cca055c4a.
# Portability: paths from source/env; synthetic key strings constructed; per-file fault
# injector covers committed-blob reads. All 38 case names/expectations preserved.
from pathlib import Path
import subprocess,os,json,yaml,tempfile,shutil,csv
receipt=Path(os.environ['SECRET_SCAN_RECEIPT']);receipt.mkdir(parents=True,exist_ok=True)
workflow=Path(__file__).resolve().parents[1]/'.github/workflows/security-secret-scan.yml'
def run_matrix(label):
 d=yaml.safe_load(workflow.read_text());step=next(s for s in d['jobs']['secret-scan']['steps'] if s.get('name')=='Run secret scan');body=step['run']
 envbase=dict(os.environ);envbase.update(GIT_CONFIG_GLOBAL='/dev/null',GIT_CONFIG_SYSTEM='/dev/null',GIT_CONFIG_NOSYSTEM='1')
 fixtures=receipt/('fixtures-'+label);fixtures.mkdir(mode=0o700,exist_ok=True)
 repo=fixtures/'git';repo.mkdir(exist_ok=True)
 def git(*args):
  r=subprocess.run(['git',*args],cwd=repo,env=envbase,capture_output=True,text=True)
  if r.returncode:raise RuntimeError('Synthetic fixture Git operation failed')
  return r.stdout.strip()
 git('init','--template=','-b','fixture')
 (repo/'source.txt').write_text('ordinary original source\n');git('add','--','source.txt');git('-c','user.name=Synthetic Fixture','-c','user.email=fixture@example.invalid','-c','commit.gpgsign=false','commit','-m','synthetic baseline');base=git('rev-parse','HEAD')
 aws='AKIA'+'A'*16;gh='ghp_'+'A'*36;jwt='eyJSyntheticHeader.eyJSyntheticPayload.SyntheticSignature';pk='-----BEGIN '+'PRIVATE KEY-----'
 # All values are synthetic; none are used for authentication or transmitted.
 filenames=['ordinary.txt','space name.txt','line\nbreak.txt','quote\"name.txt','literal[glob]*.txt','--option.txt','unicode-é.txt']
 for n in filenames:(repo/n).write_text('ordinary changed content\n')
 git('add','--',*filenames);git('-c','user.name=Synthetic Fixture','-c','user.email=fixture@example.invalid','-c','commit.gpgsign=false','commit','-m','synthetic clean changes');clean=git('rev-parse','HEAD')
 cases=[]
 def case(name,expected,range_value=None,script='',env_extra=None,redact_values=()):
  env=envbase.copy();env.update(DIFF_RANGE=range_value if range_value is not None else base+'..'+clean,SCAN_SCRIPT=script)
  if env_extra:env.update(env_extra)
  result=subprocess.run(['bash','--noprofile','--norc','-e','-o','pipefail','-c',body],cwd=repo,env=env,capture_output=True,text=True,timeout=15)
  actual='ZERO' if result.returncode==0 else 'NONZERO';redacted=all(v not in result.stdout+result.stderr for v in redact_values)
  row={'CASE':name,'EXPECTED':expected,'ACTUAL':actual,'RETURN_CODE':result.returncode,'REDACTION_PASS':redacted,'RESULT':'PASS' if actual==expected and redacted else 'FAIL'};cases.append(row)
 case('CLEAN_ORDINARY_SOURCE','ZERO')
 for name,value in [('FAKE_AWS',aws),('FAKE_GITHUB',gh),('FAKE_PRIVATE_KEY',pk),('FAKE_RSA_PRIVATE_KEY','-----BEGIN RSA '+'PRIVATE KEY-----'),('FAKE_JWT',jwt),('FAKE_STRIPE_LIVE','sk_live_'+'A'*24),('FAKE_GITHUB_OAUTH','gho_'+'A'*36),('FAKE_GITHUB_PAT','github_pat_'+'A'*82)]:
  (repo/'source.txt').write_text('synthetic=' +value+'\n');git('add','--','source.txt');git('-c','user.name=Synthetic Fixture','-c','user.email=fixture@example.invalid','-c','commit.gpgsign=false','commit','-m','synthetic detector fixture');head=git('rev-parse','HEAD');case(name,'NONZERO',clean+'..'+head,redact_values=(value,));clean=head
 # Secret-shaped content preceded by ++ must still be scanned inside a hunk.
 (repo/'source.txt').write_text('++ '+aws+'\n');git('add','--','source.txt');git('-c','user.name=Synthetic Fixture','-c','user.email=fixture@example.invalid','-c','commit.gpgsign=false','commit','-m','synthetic leading-plus fixture');head=git('rev-parse','HEAD');case('LEADING_PLUS_SECRET','NONZERO',clean+'..'+head,redact_values=(aws,));clean=head
 for i,n in enumerate(filenames[1:]):
  (repo/n).write_text(aws+'\n');git('add','--',n);git('-c','user.name=Synthetic Fixture','-c','user.email=fixture@example.invalid','-c','commit.gpgsign=false','commit','-m','synthetic filename fixture');head=git('rev-parse','HEAD');case('FILENAME_'+str(i),'NONZERO',clean+'..'+head,redact_values=(aws,));clean=head
 (repo/'source.txt').write_text('ordinary safe replacement\n');git('add','--','source.txt');git('-c','user.name=Synthetic Fixture','-c','user.email=fixture@example.invalid','-c','commit.gpgsign=false','commit','-m','synthetic removal');head=git('rev-parse','HEAD');safe_range=clean+'..'+head;case('SECRET_REMOVAL_ONLY','ZERO',safe_range)
 scripts={}
 for name,source in {'success':'process.exitCode = 0;','detection':'process.exitCode = 1;','error':'throw new Error("Synthetic scanner execution error");','syntax':'this is deliberately invalid javascript !!!'}.items():
  f=fixtures/('custom '+name+'.cjs');f.write_text(source+'\n');scripts[name]=str(f)
 case('CUSTOM_SCANNER_SUCCESS','ZERO',safe_range,scripts['success'])
 case('CUSTOM_SCANNER_DETECTION','NONZERO',safe_range,scripts['detection'])
 case('CUSTOM_SCANNER_EXECUTION_ERROR','NONZERO',safe_range,scripts['error'])
 case('CUSTOM_SCANNER_SYNTAX_ERROR','NONZERO',safe_range,scripts['syntax'])
 case('CUSTOM_SCANNER_MISSING','NONZERO',safe_range,str(fixtures/'missing.cjs'))
 case('CUSTOM_SCANNER_DIRECTORY','NONZERO',safe_range,str(fixtures))
 for name,rv in [('MISSING_RANGE',''),('MALFORMED_OPTION_RANGE','--stat'),('MALFORMED_HEAD_ONLY','HEAD'),('MALFORMED_TEXT','not-a-range'),('UNREADABLE_SHA_RANGE','0'*40+'..'+'1'*40),('MISSING_ANCESTOR_RANGE',base+'^..'+base)]:
  case(name,'NONZERO',rv)
  case(name+'_CUSTOM_SUCCESS','NONZERO',rv,scripts['success'])
 # Explicit Git subprocess failures for list and per-file reads.
 realgit=shutil.which('git');fake=fixtures/'fake-bin';fake.mkdir(exist_ok=True);fg=fake/'git'
 fg.write_text('#!/usr/bin/python3\nimport os,sys\nargs=sys.argv[1:]\nif os.environ.get("FAIL_GIT") == "all" or (os.environ.get("FAIL_GIT") == "file" and ("diff" in args or "cat-file" in args) and "--name-only" not in args):\n sys.exit(23)\nos.execv(os.environ["REAL_GIT"],[os.environ["REAL_GIT"],*args])\n');fg.chmod(0o700)
 for kind in ['all','file']:
  extra={'PATH':str(fake)+os.pathsep+envbase['PATH'],'FAIL_GIT':kind,'REAL_GIT':realgit}
  case('GIT_ERROR_'+kind.upper(),'NONZERO',safe_range,env_extra=extra)
 case('CUSTOM_SUCCESS_GIT_ERROR','NONZERO',safe_range,scripts['success'],env_extra={'PATH':str(fake)+os.pathsep+envbase['PATH'],'FAIL_GIT':'all','REAL_GIT':realgit})
 (receipt/('BEHAVIOR-'+label+'.json')).write_text(json.dumps(cases,indent=2)+'\n')
 with (receipt/('BEHAVIOR-'+label+'.tsv')).open('w') as f:
  w=csv.DictWriter(f,fieldnames=list(cases[0]),delimiter='\t');w.writeheader();w.writerows(cases)
 print(json.dumps({'phase':label,'cases':len(cases),'passed':sum(r['RESULT']=='PASS' for r in cases),'failed':[r['CASE'] for r in cases if r['RESULT']=='FAIL']}))
 return cases
if __name__=='__main__':
 import sys
 run_matrix(sys.argv[1] if len(sys.argv)>1 else 'final')
