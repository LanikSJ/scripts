#!/usr/bin/env python3
"""
Script to check if an SSL certificate for a given website has expired.
"""

import ssl
import socket
import datetime
import argparse
import sys
from urllib.parse import urlparse

# Terminal colors and icons
class Colors:
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    BLUE = '\033[94m'
    RESET = '\033[0m'

class Icons:
    INFO = 'ℹ'
    SUCCESS = '✓'
    WARNING = '⚠'
    ERROR = '✗'


def get_ssl_expiry_date(hostname, port=443):
    """
    Get the expiry date of an SSL certificate for a given hostname.
    
    Args:
        hostname (str): The hostname to check
        port (int): The port to connect to (default: 443)
        
    Returns:
        datetime.datetime: The expiry date of the certificate
    """
    context = ssl.create_default_context()
    
    try:
        with socket.create_connection((hostname, port), timeout=10) as sock:
            with context.wrap_socket(sock, server_hostname=hostname) as ssock:
                cert = ssock.getpeercert()
                expire_date_str = cert['notAfter']
                # Certificate date format: 'May 30 00:00:00 2023 GMT'
                expire_date = datetime.datetime.strptime(expire_date_str, "%b %d %H:%M:%S %Y %Z")
                return expire_date
    except (socket.gaierror, socket.timeout, ssl.SSLError, ConnectionRefusedError) as e:
        print(f"{Colors.RED}{Icons.ERROR} Error connecting to {hostname}:{port} - {e}{Colors.RESET}")
        sys.exit(1)


def check_ssl_expiry(url, days_warning=30):
    """
    Check if an SSL certificate is expired or will expire soon.
    
    Args:
        url (str): The URL to check
        days_warning (int): Number of days to warn before expiry
        
    Returns:
        tuple: (is_expired, days_remaining, expiry_date)
    """
    parsed_url = urlparse(url)
    
    # Extract hostname from the URL
    hostname = parsed_url.netloc
    if not hostname:
        hostname = parsed_url.path
    
    # Remove port if present in the hostname
    if ':' in hostname:
        hostname = hostname.split(':')[0]
    
    # Get the expiry date
    expiry_date = get_ssl_expiry_date(hostname)
    
    # Calculate days remaining
    current_date = datetime.datetime.now()
    days_remaining = (expiry_date - current_date).days
    
    # Check if expired
    is_expired = days_remaining < 0
    
    return is_expired, days_remaining, expiry_date


def main():
    """Main function to parse arguments and check SSL expiry."""
    parser = argparse.ArgumentParser(description='Check if an SSL certificate is expired.')
    parser.add_argument('url', help='URL to check (e.g., example.com or https://example.com)')
    parser.add_argument('-w', '--warning', type=int, default=30,
                        help='Days before expiry to give warning (default: 30)')
    args = parser.parse_args()
    
    # Ensure URL has a scheme
    url = args.url
    if not url.startswith(('http://', 'https://')):
        url = f"https://{url}"
    
    try:
        is_expired, days_remaining, expiry_date = check_ssl_expiry(url, args.warning)
        
        print(f"{Colors.BLUE}{Icons.INFO}{Colors.RESET} Checking SSL certificate for: {url}")
        print(f"{Colors.BLUE}{Icons.INFO}{Colors.RESET} Expiry date: {expiry_date.strftime('%Y-%m-%d')}")
        
        if is_expired:
            print(f"{Colors.RED}{Icons.ERROR} EXPIRED: Certificate has expired {abs(days_remaining)} days ago!{Colors.RESET}")
            sys.exit(2)
        elif days_remaining <= args.warning:
            print(f"{Colors.YELLOW}{Icons.WARNING} WARNING: Certificate expires in {days_remaining} days!{Colors.RESET}")
            sys.exit(1)
        else:
            print(f"{Colors.GREEN}{Icons.SUCCESS} OK: Certificate is valid for {days_remaining} more days.{Colors.RESET}")
            sys.exit(0)
    except Exception as e:
        print(f"{Colors.RED}{Icons.ERROR} Error: {e}{Colors.RESET}")
        sys.exit(1)


if __name__ == "__main__":
    main()
