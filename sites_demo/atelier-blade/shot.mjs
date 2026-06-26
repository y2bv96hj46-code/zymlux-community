import { chromium } from '/opt/node22/lib/node_modules/playwright/index.mjs';
const path = 'file://' + process.cwd() + '/index.html';
const css = `.reveal{opacity:1!important;transform:none!important}
.mmenu{display:none!important}.float-book{display:none!important}
*{animation:none!important}`;
const b = await chromium.launch();
async function shoot(file, vp, mobile){
  const p = await b.newPage({ viewport:vp, deviceScaleFactor:2, isMobile:!!mobile });
  await p.goto(path,{waitUntil:'networkidle'});
  await p.addStyleTag({content:css});
  await p.waitForTimeout(1500); // let counters/fonts settle
  await p.screenshot({path:file, fullPage:true});
  await p.close();
}
await shoot('preview_desktop.png',{width:1280,height:900},false);
await shoot('preview_mobile.png',{width:390,height:844},true);
await b.close();
console.log('done');
