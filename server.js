const http=require('http'),fs=require('fs'),path=require('path');
const PORT=process.env.PORT||3000, ROOT=__dirname;
const MIME={'.html':'text/html; charset=utf-8','.css':'text/css','.js':'application/javascript','.svg':'image/svg+xml','.png':'image/png','.jpg':'image/jpeg','.webp':'image/webp','.ico':'image/x-icon','.woff2':'font/woff2'};
http.createServer((req,res)=>{
  let p=decodeURIComponent(req.url.split('?')[0]); if(p==='/'||!p)p='/index.html';
  if(p==='/es'||p==='/es/')p='/es.html';
  const f=path.join(ROOT,p);
  if(!f.startsWith(ROOT)){res.writeHead(403);res.end();return;}
  fs.readFile(f,(e,d)=>{
    if(e){res.writeHead(404);res.end('Not found');return;}
    res.writeHead(200,{'Content-Type':MIME[path.extname(f).toLowerCase()]||'application/octet-stream','Cache-Control':'public, max-age=3600'});
    res.end(d);
  });
}).listen(PORT,()=>console.log('Listening on '+PORT));
