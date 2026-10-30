export const legalLinks = {
  privacy: "grainbook://entry/privacy",
  terms: "grainbook://entry/terms",
  support: "grainbook://entry/support",
};

export function openLegal(name) {
  const url = legalLinks[name];
  if (!url) return { ok: false, message: "無法啟動" };
  window.open(url);
  return { ok: true, url, protocol: "pop" };
}
