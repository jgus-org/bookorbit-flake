import cloudscraper
from cloudscraper.interpreters import JavaScriptInterpreter
from cloudscraper.interpreters.native import Calc

JavaScriptInterpreter.dynamicImport("native")
if Calc.doMath("1 + 2 * 3") != 7:
    raise RuntimeError("cloudscraper native interpreter arithmetic failed")


class Response:
    status_code = 200
    url = "https://www.kobo.com/test"
    headers = {"server": "fixture"}
    text = "<html>fixture</html>"


original_create_scraper = cloudscraper.create_scraper


def fixture_get(url, timeout):
    return Response()


def create_scraper(**kwargs):
    if kwargs.get("interpreter") != "native":
        raise RuntimeError(
            "BookOrbit did not select the native cloudscraper interpreter"
        )
    scraper = original_create_scraper(**kwargs)
    scraper.get = fixture_get
    return scraper


cloudscraper.create_scraper = create_scraper
