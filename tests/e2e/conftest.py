"""Shared fixtures: base URL of the nginx front end + readiness wait."""
import os
import time

import pytest
import requests


# ----------------------------------------------------------------- Config ---

PHP_URL = os.environ.get("PHP_URL", "http://nginx:8080")


# ----------------------------------------------------------- Helpers -------

def wait_for_http(url: str, timeout: int = 60) -> None:
    """Wait until the server answers at all (any HTTP status counts as up)."""
    deadline = time.time() + timeout
    last = None
    while time.time() < deadline:
        try:
            requests.get(url, timeout=2)
            return
        except requests.RequestException as exc:  # connection refused / reset
            last = exc
            time.sleep(1)
    raise TimeoutError(f"{url} did not become ready within {timeout}s: {last}")


def get(url: str, path: str, **kwargs) -> requests.Response:
    return requests.get(url + path, timeout=10, **kwargs)


# --------------------------------------------------------- Fixtures --------

@pytest.fixture(scope="session", autouse=True)
def wait_for_services():
    wait_for_http(PHP_URL + "/")
