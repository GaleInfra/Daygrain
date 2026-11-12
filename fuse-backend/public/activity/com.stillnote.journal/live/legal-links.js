export const legalLinks = {
  privacy: "https://pollen-notch-fieldwalk.pages.dev/privacy/",
  terms: "https://pollen-notch-fieldwalk.pages.dev/terms/",
  support: "https://pollen-notch-fieldwalk.pages.dev/support/",
};

export function openLegal(name) {
  const url = legalLinks[name];
  if (!url) return { ok: false, message: "無法啟動" };
  window.open(url);
  return { ok: true, url, protocol: "pop" };
}
