import fs from "node:fs/promises";
import path from "node:path";
import sharp from "sharp";

const projectRoot = path.resolve(import.meta.dirname, "..");
const colors = {
  dark: "#0F2B1F",
  green: "#A7E632",
  offWhite: "#F8F8F5",
  text: "#1F1F1F",
  gray: "#8A8A8A",
};

const typePaths = JSON.parse(await fs.readFile(path.join(projectRoot, "assets/source/rallyup-inter-paths.json"), "utf8"));
const generatedFiles = new Set();
const logoText = (x, baseline, darkColor, accentColor, width) => {
  const source = typePaths.wordmark;
  const scale = width / source.width;
  const transform = `translate(${x} ${baseline}) scale(${scale} -1)`;
  return `<g transform="${transform}" fill="${darkColor}"><path d="${source.groups.rally}"/></g><g transform="${transform}" fill="${accentColor}"><path d="${source.groups.up}"/></g>`;
};

function outlinedTagline({ color, x, centerX, baseline, size = 19 }) {
  const source = typePaths.tagline;
  const scale = size / 19;
  const startX = x ?? centerX - source.width * scale / 2;
  return `<g transform="translate(${startX} ${baseline}) scale(${scale} -${scale})" fill="${color}"><path d="${source.groups.text}"/></g>`;
}

function ballSymbol({ cx, cy, radius, fill, seam, seamWidth = radius * 0.2, cutout = false, id = "ball-mask" }) {
  const mask = cutout ? `<mask id="${id}" x="${cx - radius}" y="${cy - radius}" width="${radius * 2}" height="${radius * 2}" maskUnits="userSpaceOnUse"><circle cx="${cx}" cy="${cy}" r="${radius}" fill="white"/><path d="M ${cx - radius * 0.88} ${cy + radius * 0.18} C ${cx - radius * 0.38} ${cy + radius * 0.56}, ${cx - radius * 0.05} ${cy + radius * 0.24}, ${cx + radius * 0.18} ${cy - radius * 0.28} C ${cx + radius * 0.4} ${cy - radius * 0.72}, ${cx + radius * 0.65} ${cy - radius * 0.62}, ${cx + radius * 0.9} ${cy - radius * 0.48}" fill="none" stroke="black" stroke-width="${seamWidth}" stroke-linecap="round"/></mask>` : "";
  const maskAttr = cutout ? ` mask="url(#${id})"` : "";
  const seamPath = `<path d="M ${cx - radius * 0.88} ${cy + radius * 0.18} C ${cx - radius * 0.38} ${cy + radius * 0.56}, ${cx - radius * 0.05} ${cy + radius * 0.24}, ${cx + radius * 0.18} ${cy - radius * 0.28} C ${cx + radius * 0.4} ${cy - radius * 0.72}, ${cx + radius * 0.65} ${cy - radius * 0.62}, ${cx + radius * 0.9} ${cy - radius * 0.48}" fill="none" stroke="${seam}" stroke-width="${seamWidth}" stroke-linecap="round"/>`;
  return `${mask}<circle cx="${cx}" cy="${cy}" r="${radius}" fill="${fill}"${maskAttr}/>${cutout ? "" : seamPath}`;
}

function trajectory({ color, ball, seam, scale = 1, x = 0, y = 0, cutoutBall = false, id = "trajectory-ball" }) {
  return `<g transform="translate(${x} ${y}) scale(${scale})">
    <path d="M 263 137 C 315 73, 400 68, 472 117 C 413 89, 337 90, 267 142 Z" fill="${color}"/>
    <path d="M 489 135 C 497 121, 507 107, 519 94" fill="none" stroke="${color}" stroke-width="9" stroke-linecap="round"/>
    ${ballSymbol({ cx: 548, cy: 73, radius: 31, fill: ball, seam, seamWidth: 5.5, cutout: cutoutBall, id })}
  </g>`;
}

function rMarkArtwork({ fill, track, ball, seam, cutout = false, id = "r-mark-ball" }) {
  const mark = typePaths.mark;
  const markScale = 177 / mark.width;
  return `<path d="M 35 145 C 94 73, 199 70, 269 129 C 212 96, 111 95, 40 149 Z" fill="${track}"/>
    <path d="M 284 138 C 294 123, 305 107, 316 93" fill="none" stroke="${track}" stroke-width="9" stroke-linecap="round"/>
    ${ballSymbol({ cx: 334, cy: 72, radius: 31, fill: ball, seam, seamWidth: 5.5, cutout, id })}
    <path d="${mark.groups.mark}" transform="translate(75 263) scale(${markScale} -1)" fill="${fill}"/>`;
}

function titleBlock(title, description, width, height, body) {
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}" viewBox="0 0 ${width} ${height}" role="img" aria-labelledby="title desc">
    <title id="title">${title}</title><desc id="desc">${description}</desc>${body}
  </svg>`;
}

function stackedLogo({ dark = colors.text, accent = colors.green, tagline = false, allOneColor = false }) {
  const wordDark = allOneColor ? dark : dark;
  const wordAccent = allOneColor ? dark : accent;
  const ballFill = allOneColor ? dark : accent;
  const seam = allOneColor ? "transparent" : colors.offWhite;
  const track = allOneColor ? dark : dark;
  const content = `${trajectory({ color: track, ball: ballFill, seam, x: 0, y: 0, cutoutBall: allOneColor })}
    ${logoText(86, 255, wordDark, wordAccent, 488)}
    ${tagline ? outlinedTagline({ color: allOneColor ? dark : colors.text, centerX: 320, baseline: 302, size: 22 }) : ""}`;
  return titleBlock(
    tagline ? "RallyUp primary logo with tagline" : "RallyUp logo",
    tagline ? "RallyUp wordmark with its tennis trajectory, ball, and FIND YOUR MATCH tagline." : "RallyUp wordmark with tennis trajectory and ball. Transparent background.",
    640,
    tagline ? 324 : 276,
    content,
  );
}

function horizontalLogo() {
  const body = `<g transform="translate(0 4) scale(.78)">
      ${trajectory({ color: colors.dark, ball: colors.green, seam: colors.offWhite })}
      ${logoText(86, 255, colors.text, colors.green, 488)}
    </g>
    <path d="M 521 62 V 190" stroke="#D6DBD2" stroke-width="2"/>
    ${outlinedTagline({ color: colors.text, x: 566, baseline: 143, size: 22 })}`;
  return titleBlock("RallyUp horizontal logo", "Compact horizontal RallyUp wordmark with the optional tagline, for navigation, headers, authentication, and marketing layouts.", 1040, 236, body);
}

function markSvg({ fill = colors.text, track = colors.dark, ball = colors.green, seam = colors.offWhite, cutout = false, title = "RallyUp mark" } = {}) {
  const body = `<g>${rMarkArtwork({ fill, track, ball, seam, cutout, id: "mark-ball-cutout" })}</g>`;
  return titleBlock(title, "Standalone italic RallyUp R with the approved curved tennis trajectory and ball motif.", 400, 300, body);
}

function ballLogoSvg() {
  return titleBlock("RallyUp tennis ball mark", "Standalone tennis ball symbol with the RallyUp curved seam motif.", 128, 128,
    ballSymbol({ cx: 64, cy: 64, radius: 58, fill: colors.green, seam: colors.offWhite, seamWidth: 8 }));
}

function appIconSvg({ background, mark, trajectory: trajectoryColor, ball, seam, title }) {
  const body = `<rect width="1024" height="1024" fill="${background}"/>
    <g transform="translate(72 178) scale(2.2)">
      ${rMarkArtwork({ fill: mark, track: trajectoryColor, ball, seam, cutout: seam === "transparent", id: "app-icon-ball-cutout" })}
    </g>`;
  return titleBlock(title, "Square RallyUp mobile app icon. Keep the full-bleed square artwork; the operating system applies its platform-specific icon mask.", 1024, 1024, body);
}

function splashSvg() {
  return titleBlock("RallyUp splash screen logo", "Centered RallyUp wordmark with tennis trajectory and ball on a transparent canvas.", 1024, 1024,
    `<g transform="translate(165 361) scale(1)">${trajectory({ color: colors.dark, ball: colors.green, seam: colors.offWhite })}${logoText(86, 255, colors.text, colors.green, 488)}</g>`);
}

function faviconSvg() {
  return titleBlock("RallyUp favicon", "Simplified RallyUp tennis ball on a deep-green tile for small browser and shortcut icons.", 64, 64,
    `<rect width="64" height="64" rx="15" fill="${colors.dark}"/>${ballSymbol({ cx: 32, cy: 32, radius: 23, fill: colors.green, seam: colors.dark, seamWidth: 6.5 })}`);
}

async function ensureDirectory(filePath) {
  await fs.mkdir(path.dirname(filePath), { recursive: true });
}

async function writeText(relativePath, content) {
  const filePath = path.join(projectRoot, relativePath);
  await ensureDirectory(filePath);
  await fs.writeFile(filePath, content.trimStart(), "utf8");
  generatedFiles.add(path.relative(projectRoot, filePath));
}

async function writePng(relativePath, svg, width, height, opaque = false) {
  const filePath = path.join(projectRoot, relativePath);
  await ensureDirectory(filePath);
  let pipeline = sharp(Buffer.from(svg)).resize(width, height, { fit: "contain", background: { r: 0, g: 0, b: 0, alpha: 0 } });
  if (opaque) pipeline = pipeline.removeAlpha();
  await pipeline.png({ compressionLevel: 9 }).toFile(filePath);
  generatedFiles.add(path.relative(projectRoot, filePath));
}

const logoSvg = stackedLogo({});
const primarySvg = stackedLogo({ tagline: true });
const mark = markSvg();
const ballSvg = ballLogoSvg();
const monoDark = stackedLogo({ dark: colors.dark, accent: colors.dark, allOneColor: true });
const monoLight = stackedLogo({ dark: "#FFFFFF", accent: "#FFFFFF", allOneColor: true });
const darkBackground = stackedLogo({ dark: "#FFFFFF", accent: colors.green });
const horizontal = horizontalLogo();
const splash = splashSvg();
const favicon = faviconSvg();
const suppliedAppIcon = await fs.readFile(path.join(projectRoot, "assets/source/rallyup-app-icon-light.png"));
const suppliedAppIconData = `data:image/png;base64,${suppliedAppIcon.toString("base64")}`;

const appIcons = {
  standard: titleBlock(
    "RallyUp app icon",
    "RallyUp primary mobile app icon, using the supplied light alternate icon artwork.",
    1024,
    1024,
    `<image href="${suppliedAppIconData}" x="0" y="0" width="1024" height="1024"/>`,
  ),
  green: appIconSvg({ background: colors.green, mark: colors.dark, trajectory: colors.dark, ball: colors.dark, seam: colors.green, title: "RallyUp alternate green app icon" }),
  light: appIconSvg({ background: colors.offWhite, mark: colors.dark, trajectory: colors.dark, ball: colors.green, seam: colors.offWhite, title: "RallyUp light app icon" }),
};

const brandingAssets = [
  ["branding/rallyup-logo-primary.svg", primarySvg, 2560],
  ["branding/rallyup-logo.svg", logoSvg, 2560],
  ["branding/rallyup-logo-horizontal.svg", horizontal, 2560],
  ["branding/rallyup-mark.svg", mark, 1200],
  ["branding/rallyup-ball.svg", ballSvg, 512],
  ["branding/rallyup-logo-dark.svg", monoDark, 2560],
  ["branding/rallyup-logo-light.svg", monoLight, 2560],
  ["branding/rallyup-logo-dark-background.svg", darkBackground, 2560],
];

for (const [name, svg, width] of brandingAssets) {
  await writeText(path.join("public/assets", name), svg);
  const height = Math.round(width * (name.endsWith("horizontal.svg") ? 236 / 1040 : name.endsWith("primary.svg") ? 324 / 640 : name.endsWith("ball.svg") ? 1 : name.endsWith("mark.svg") ? 300 / 400 : 276 / 640));
  const pngName = name.replace(/\.svg$/, ".png");
  await writePng(path.join("public/assets", pngName), svg, width, height);
}

for (const [key, assetName] of [["standard", "rallyup-app-icon"], ["green", "rallyup-app-icon-green"], ["light", "rallyup-app-icon-light"]]) {
  const svg = appIcons[key];
  await writeText(`public/assets/app-icons/${assetName}.svg`, svg);
  await writePng(`public/assets/app-icons/${assetName}.png`, svg, 1024, 1024, true);
}

await writeText("public/assets/splash/rallyup-splash-logo.svg", splash);
await writePng("public/assets/splash/rallyup-splash-logo.png", splash, 2048, 2048);
await writeText("public/assets/favicon/rallyup-favicon.svg", favicon);
for (const size of [16, 32, 48, 64]) await writePng(`public/assets/favicon/rallyup-favicon-${size}.png`, favicon, size, size, true);

const iconSizes = [
  ["iphone", "20x20", "2x", 40], ["iphone", "20x20", "3x", 60],
  ["iphone", "29x29", "2x", 58], ["iphone", "29x29", "3x", 87],
  ["iphone", "40x40", "2x", 80], ["iphone", "40x40", "3x", 120],
  ["iphone", "60x60", "2x", 120], ["iphone", "60x60", "3x", 180],
  ["ipad", "20x20", "1x", 20], ["ipad", "20x20", "2x", 40],
  ["ipad", "29x29", "1x", 29], ["ipad", "29x29", "2x", 58],
  ["ipad", "40x40", "1x", 40], ["ipad", "40x40", "2x", 80],
  ["ipad", "76x76", "1x", 76], ["ipad", "76x76", "2x", 152],
  ["ipad", "83.5x83.5", "2x", 167], ["ios-marketing", "1024x1024", "1x", 1024],
];

const iosSets = [
  ["standard", "AppIcon"],
  ["green", "AppIcon-Green"],
  ["light", "AppIcon-Light"],
];

for (const [iconKey, setName] of iosSets) {
  const directory = path.join("native/ios/Assets.xcassets", `${setName}.appiconset`);
  const images = [];
  for (const [idiom, size, scale, pixels] of iconSizes) {
    const filename = `RallyUp-${size.replaceAll("x", "-")}-${scale}.png`;
    images.push({ filename, idiom, size, scale });
    await writePng(path.join(directory, filename), appIcons[iconKey], pixels, pixels, true);
  }
  await writeText(path.join(directory, "Contents.json"), JSON.stringify({ images, info: { author: "xcode", version: 1 } }, null, 2));
}
await writeText("native/ios/Assets.xcassets/Contents.json", JSON.stringify({ info: { author: "xcode", version: 1 } }, null, 2));

const androidSizes = { mdpi: 48, hdpi: 72, xhdpi: 96, xxhdpi: 144, xxxhdpi: 192 };
for (const [density, size] of Object.entries(androidSizes)) {
  await writePng(`native/android/res/mipmap-${density}/ic_launcher.png`, appIcons.standard, size, size, true);
  await writePng(`native/android/res/mipmap-${density}/ic_launcher_round.png`, appIcons.standard, size, size, true);
}

const foreground = titleBlock("RallyUp adaptive icon foreground", "Supplied light RallyUp app icon artwork for Android adaptive launcher icons.", 432, 432,
  `<image href="${suppliedAppIconData}" x="0" y="0" width="432" height="432"/>`);
await writeText("public/assets/app-icons/rallyup-app-icon-foreground.svg", foreground);
await writePng("public/assets/app-icons/rallyup-app-icon-foreground.png", foreground, 432, 432);
await writePng("native/android/res/drawable-nodpi/rallyup_launcher_foreground.png", foreground, 432, 432);
await writeText("native/android/res/mipmap-anydpi-v26/ic_launcher.xml", `<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/rallyup_icon_background" />
    <foreground android:drawable="@drawable/rallyup_launcher_foreground" />
</adaptive-icon>`);
await writeText("native/android/res/mipmap-anydpi-v26/ic_launcher_round.xml", `<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/rallyup_icon_background" />
    <foreground android:drawable="@drawable/rallyup_launcher_foreground" />
</adaptive-icon>`);
await writeText("native/android/res/values/rallyup_icon_background.xml", `<?xml version="1.0" encoding="utf-8"?>
<resources><color name="rallyup_icon_background">${colors.offWhite}</color></resources>`);
await writePng("native/android/play-store-icon-512.png", appIcons.standard, 512, 512, true);

// The current web app already uses this stable public path for its browser icon.
await writeText(path.join("public", "favicon.svg"), favicon);

console.log(`Generated ${generatedFiles.size} logo and launcher files.`);
