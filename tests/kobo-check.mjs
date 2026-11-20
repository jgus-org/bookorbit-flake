const root = process.env.BOOKORBIT_ROOT;
const module = await import(
  `${root}/lib/bookorbit/dist/modules/metadata-fetch/providers/kobo/kobo-cloudscraper.fetcher.js`
);
const { fetchKoboHtmlWithCloudscraper } = module.default ?? module;

const result = await fetchKoboHtmlWithCloudscraper(
  "https://www.kobo.com/test",
  {
    pythonPath: process.env.KOBO_CLOUDSCRAPER_PYTHON,
    timeoutMs: 5000,
  },
);

if (
  result.status !== 200 ||
  result.html !== "<html>fixture</html>" ||
  result.attempts !== 1
) {
  throw new Error(
    `Unexpected Kobo cloudscraper result: ${JSON.stringify(result)}`,
  );
}
