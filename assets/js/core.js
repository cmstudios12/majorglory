const sb=window.supabase.createClient(CM_CONFIG.SUPABASE_URL,CM_CONFIG.SUPABASE_KEY);
const qs=(s,r=document)=>r.querySelector(s), qsa=(s,r=document)=>[...r.querySelectorAll(s)];
function toast(msg){let t=qs('.toast');if(!t){t=document.createElement('div');t.className='toast';document.body.appendChild(t)}t.textContent=msg;t.classList.remove('hidden');clearTimeout(window.__toast);window.__toast=setTimeout(()=>t.classList.add('hidden'),2600)}
function esc(v=''){return String(v).replace(/[&<>"']/g,m=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#039;'}[m]))}
async function getSession(){const {data:{session}}=await sb.auth.getSession();return session}
async function requireAuth(){const s=await getSession();if(!s){location.href='auth.html';throw new Error('AUTH_REQUIRED')}return s}
async function loadProfile(uid){const {data}=await sb.from('profiles').select('*').eq('id',uid).maybeSingle();return data}
async function logout(){await sb.auth.signOut();location.href='index.html'}
function bindLogout(){qsa('[data-logout]').forEach(b=>b.onclick=logout)}
function formatDate(v){try{return new Intl.DateTimeFormat('en-ZA',{day:'2-digit',month:'short',year:'numeric'}).format(new Date(v))}catch{return ''}}
function blankCv(){return {firstName:'',lastName:'',headline:'',email:'',phone:'',location:'',linkedin:'',summary:'',skills:'',experience:[],education:[],projects:[],certifications:'',languages:'',references:[]}}
function cvScore(cv){let s=0;if(cv.firstName||cv.lastName)s+=8;if(cv.headline)s+=8;if(cv.email)s+=8;if(cv.phone)s+=5;if(cv.location)s+=4;if((cv.summary||'').length>80)s+=15;if((cv.experience||[]).some(x=>x.role||x.company))s+=18;if((cv.education||[]).some(x=>x.qualification||x.institution))s+=12;if((cv.skills||'').split(',').filter(Boolean).length>=5)s+=12;if((cv.projects||[]).length)s+=5;if(cv.linkedin)s+=3;if(cv.certifications)s+=2;return Math.min(100,s)}
function renderAppUser(profile,session){const n=profile?`${profile.first_name||''} ${profile.last_name||''}`.trim():'';qsa('[data-user-name]').forEach(e=>e.textContent=n||session?.user?.email||'Account')}
