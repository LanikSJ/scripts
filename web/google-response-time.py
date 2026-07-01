#!/usr/bin/env python3
"""
Google Response Time Tester — Beginner-Friendly Version
=======================================================

This script measures how long it takes to get a response from a website
(by default, google.com).  It sends HTTP requests and times how many
milliseconds elapse before the server replies.

Why this is useful:
  - Check if a website is slow or down
  - Compare performance from your network location
  - Understand web latency basics

Usage:
    python3 google-response-time.py           # 3 pings to google.com
    python3 google-response-time.py 5         # 5 pings to google.com
    python3 google-response-time.py 3 https://example.com   # custom URL

What you'll learn:
  - How to send HTTP requests with Python
  - How to time code execution with time.perf_counter()
  - How to calculate basic statistics (min, max, average, etc.)
"""

# ============================================================================
# IMPORTS — these are "toolboxes" that give us extra powers.
# ============================================================================
import sys      # sys lets us read command-line arguments (things you type after the script name)
import time     # time lets us measure how long things take
import statistics  # statistics calculates math like averages and medians

# ============================================================================
# CONSTANTS — values we set once and never change (written in ALL_CAPS).
# ============================================================================
TARGET_URL = "https://www.google.com"   # The default website we'll test
DEFAULT_COUNT = 3                       # How many times we'll ping by default


# ============================================================================
# FUNCTION 1: measure_requests()
# ----------------------------------------------------------------------------
# This function uses the popular 'requests' library.  If the library is not
# installed on your computer, the function returns None (meaning "sorry, I
# can't use this method") and we fall back to the built-in urllib instead.
#
# What happens step by step:
#   1. Try to import the 'requests' library.
#   2. If the import fails → return None (we'll use urllib instead).
#   3. Record the current time (start).
#   4. Send an HTTP GET request to the URL (this is like typing the URL into
#      a browser and pressing Enter).
#   5. Record the current time again (end).
#   6. Calculate elapsed = end - start.
#   7. Print the HTTP status code (200 = OK) and the elapsed time in ms.
#   8. Return the elapsed time so the main program can collect it.
# ============================================================================
def measure_requests(url: str) -> float | None:
    """Measure response time using the 'requests' library."""

    # Try to import the 'requests' library.  This library makes HTTP work
    # easier than Python's built-in tools.  If it's not installed, we
    # catch the ImportError and return None.
    try:
        import requests
    except ImportError:
        return None   # None means "no value" — tells the caller to try a different method

    # If we got here, the import succeeded.  Now let's do the actual measurement.
    try:
        # time.perf_counter() gives us a very precise timestamp (in seconds)
        start = time.perf_counter()

        # requests.get() sends an HTTP GET request — the same thing your
        # browser does when you visit a website.  The timeout=10 means
        # "give up after 10 seconds" so we don't wait forever.
        resp = requests.get(url, timeout=10)

        # Take another timestamp right after the response arrives
        elapsed = time.perf_counter() - start   # elapsed time in seconds

        # resp.status_code is the HTTP status code.  200 = success.
        # elapsed * 1000 converts seconds to milliseconds (ms).
        print(f"  → {resp.status_code}  {elapsed * 1000:.1f} ms")

        # Return the elapsed time so the main program can save it for stats
        return elapsed

    # If something goes wrong (network error, timeout, etc.), we catch the
    # exception, print a friendly error message, and return None.
    except requests.RequestException as e:
        print(f"  ✗ Error (requests): {e}")
        return None


# ============================================================================
# FUNCTION 2: measure_urllib()
# ----------------------------------------------------------------------------
# This function uses urllib, which is built into Python — no extra install
# needed!  It does the same thing as measure_requests() but with tools that
# come with every Python installation.
#
# What happens step by step:
#   1. Import urllib.request and urllib.error (built-in modules).
#   2. Record the current time (start).
#   3. Open a connection to the URL (same as visiting it in a browser).
#   4. Record the current time again (end).
#   5. Close the connection (important cleanup!).
#   6. Print the status code and elapsed time.
#   7. Return the elapsed time.
# ============================================================================
def measure_urllib(url: str) -> float | None:
    """Measure response time using built-in urllib (no extra install needed)."""

    # These are built-in modules, so no try/except needed.
    import urllib.request   # Tools for making web requests
    import urllib.error     # Error types for web request problems

    try:
        # Start the timer
        start = time.perf_counter()

        # urlopen() opens a connection to the URL and waits for a response.
        # It's like urllib's version of requests.get().
        resp = urllib.request.urlopen(url, timeout=10)

        # Stop the timer
        elapsed = time.perf_counter() - start

        # resp.status gives us the HTTP status code (200 = OK)
        print(f"  → {resp.status}  {elapsed * 1000:.1f} ms")

        # Always close the connection when we're done — good practice!
        resp.close()

        # Return the elapsed time for statistics
        return elapsed

    # If something goes wrong, print an error and return None
    except urllib.error.URLError as e:
        print(f"  ✗ Error (urllib): {e}")
        return None


# ============================================================================
# MAIN FUNCTION — the program starts here when you run the script.
# ----------------------------------------------------------------------------
# This function:
#   1. Reads command-line arguments (count and URL) or uses defaults.
#   2. Picks the best available measurement method (requests > urllib).
#   3. Runs the measurement N times and collects the times in a list.
#   4. Prints a summary with statistics.
# ============================================================================
def main() -> None:

    # ------------------------------------------------------------------
    # STEP 1: Parse command-line arguments
    # ------------------------------------------------------------------
    # sys.argv is a list containing what you type on the command line.
    #   sys.argv[0] = the script name (e.g., "google-response-time.py")
    #   sys.argv[1] = the first argument (e.g., "5")
    #   sys.argv[2] = the second argument (e.g., "https://example.com")
    # ------------------------------------------------------------------

    count = DEFAULT_COUNT   # Start with the default (3)
    url = TARGET_URL        # Start with the default (google.com)

    # If the user typed at least one argument, try to use it as the count
    if len(sys.argv) > 1:
        try:
            count = int(sys.argv[1])   # Convert the argument from text to a number
        except ValueError:
            # If the argument isn't a valid number, show usage instructions
            print(f"Usage: {sys.argv[0]} [count] [url]")
            sys.exit(1)   # Exit the program with an error code

    # If the user typed a second argument, use it as the URL
    if len(sys.argv) > 2:
        url = sys.argv[2]

    # Make sure the count is at least 1 (we need at least one measurement)
    if count < 1:
        print("Count must be at least 1.")
        sys.exit(1)

    # ------------------------------------------------------------------
    # STEP 2: Print a header so the user knows what's happening
    # ------------------------------------------------------------------
    print(f"Measuring response time for: {url}")
    print(f"Number of requests: {count}")
    print("-" * 50)   # Print a separator line (50 dashes)

    # ------------------------------------------------------------------
    # STEP 3: Choose the best measurement method
    # ------------------------------------------------------------------
    # Strategy: try 'requests' first; if it's not installed, use urllib.
    # We do this by calling measure_requests() once as a test.  If it
    # returns a value (not None), then 'requests' is available and we'll
    # use it for all measurements.  Otherwise, we'll use urllib.
    # ------------------------------------------------------------------

    measurer = measure_urllib        # Start by assuming we'll use urllib

    # Test if 'requests' is available
    if measure_requests(url) is not None:
        measurer = measure_requests  # It worked!  Use 'requests' for the real tests.
        print("(Using 'requests' library)")
    else:
        print("(Using built-in 'urllib' — install 'requests' for more features)")

    print("-" * 50)

    # ------------------------------------------------------------------
    # STEP 4: Run the measurements
    # ------------------------------------------------------------------
    # We create an empty list called 'times' to store all the elapsed times.
    # Then we loop 'count' times, calling our chosen measurer each time
    # and appending the result to the list.
    # ------------------------------------------------------------------

    times: list[float] = []   # Empty list that will hold our measurements

    # range(1, count + 1) gives us numbers 1, 2, 3, ..., count
    for i in range(1, count + 1):
        print(f"[{i}/{count}] ", end="")   # Show progress like [1/3], [2/3], etc.

        # Call whichever measurement function we chose above
        elapsed = measurer(url)

        # If the measurement succeeded (didn't return None), save it
        if elapsed is not None:
            times.append(elapsed)   # Add this time to our list

    # ------------------------------------------------------------------
    # STEP 5: Print the summary / statistics
    # ------------------------------------------------------------------
    print("-" * 50)

    # If every measurement failed, let the user know and exit
    if not times:
        print("No successful measurements.")
        sys.exit(1)

    # Show how many succeeded out of total attempts
    print(f"Successful requests : {len(times)}/{count}")

    # Basic statistics:
    #   min() = the smallest value (fastest response)
    #   max() = the largest value (slowest response)
    #   statistics.mean() = the average (sum divided by count)
    print(f"Min response time  : {min(times) * 1000:.1f} ms")
    print(f"Max response time  : {max(times) * 1000:.1f} ms")
    print(f"Average response   : {statistics.mean(times) * 1000:.1f} ms")

    # If we have more than 1 measurement, also show:
    #   stdev() = standard deviation (how spread out the times are)
    #            A small number means consistent performance.
    #   median() = the middle value when sorted (less affected by outliers)
    if len(times) > 1:
        print(f"Std deviation      : {statistics.stdev(times) * 1000:.1f} ms")
        print(f"Median response    : {statistics.median(times) * 1000:.1f} ms")


# ============================================================================
# This is Python's standard "entry point" idiom.
# When you run the script directly (python3 google-response-time.py), Python
# sets __name__ to "__main__" and calls main().  If you import this script
# from another file, main() won't run automatically.
# ============================================================================
if __name__ == "__main__":
    main()