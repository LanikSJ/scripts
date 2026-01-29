#!/bin/zsh

# FIPS mode management functions for OpenSSL
# Usage: fipson | fipsoff | fipsstatus

# Get OpenSSL FIPS config path
_fips_config_path() {
    local config_path
    config_path="$(brew --prefix 2>/dev/null)/etc/openssl-fips@3/openssl.cnf"
    
    # Fallback for different OpenSSL versions
    if [[ ! -f "$config_path" ]]; then
        config_path="$(brew --prefix 2>/dev/null)/etc/openssl@3/openssl.cnf"
    fi
    
    # Check for system OpenSSL
    if [[ ! -f "$config_path" ]]; then
        config_path="/etc/ssl/openssl.cnf"
    fi
    
    echo "$config_path"
}

# Enable FIPS mode
fipson() {
    local config_path
    config_path="$(_fips_config_path)"
    
    if [[ ! -f "$config_path" ]]; then
        echo "Error: OpenSSL configuration file not found at any of the expected locations" >&2
        echo "Tried: $(brew --prefix 2>/dev/null)/etc/openssl-fips@3/openssl.cnf" >&2
        echo "       $(brew --prefix 2>/dev/null)/etc/openssl@3/openssl.cnf" >&2
        echo "       /etc/ssl/openssl.cnf" >&2
        return 1
    fi
    
    # Check if already enabled
    if grep -q "^fips[[:space:]]*=[[:space:]]*yes" "$config_path" 2>/dev/null; then
        echo "FIPS mode is already enabled"
        return 0
    fi
    
    # Create backup
    cp "$config_path" "${config_path}.backup"
    
    # Enable FIPS mode
    if sed -i '' 's/fips[[:space:]]*=[[:space:]]*no/fips = yes/' "$config_path"; then
        echo "FIPS mode enabled successfully"
        echo "Configuration file: $config_path"
    else
        echo "Error: Failed to enable FIPS mode" >&2
        return 1
    fi
}

# Disable FIPS mode
fipsoff() {
    local config_path
    config_path="$(_fips_config_path)"
    
    if [[ ! -f "$config_path" ]]; then
        echo "Error: OpenSSL configuration file not found at any of the expected locations" >&2
        return 1
    fi
    
    # Check if already disabled
    if grep -q "^fips[[:space:]]*=[[:space:]]*no" "$config_path" 2>/dev/null; then
        echo "FIPS mode is already disabled"
        return 0
    fi
    
    # Create backup
    cp "$config_path" "${config_path}.backup"
    
    # Disable FIPS mode
    if sed -i '' 's/fips[[:space:]]*=[[:space:]]*yes/fips = no/' "$config_path"; then
        echo "FIPS mode disabled successfully"
        echo "Configuration file: $config_path"
    else
        echo "Error: Failed to disable FIPS mode" >&2
        return 1
    fi
}

# Check FIPS mode status
fipsstatus() {
    local config_path
    config_path="$(_fips_config_path)"
    
    if [[ ! -f "$config_path" ]]; then
        echo "Error: OpenSSL configuration file not found at any of the expected locations" >&2
        return 1
    fi
    
    echo "Configuration file: $config_path"
    
    # Check FIPS status
    if grep -q "^fips[[:space:]]*=[[:space:]]*yes" "$config_path" 2>/dev/null; then
        echo "FIPS mode: ENABLED"
    elif grep -q "^fips[[:space:]]*=[[:space:]]*no" "$config_path" 2>/dev/null; then
        echo "FIPS mode: DISABLED"
    else
        echo "FIPS mode: UNKNOWN (no fips directive found)"
    fi
    
    # Show the relevant line if it exists
    local fips_line
    fips_line=$(grep "^fips[[:space:]]*=" "$config_path" 2>/dev/null)
    if [[ -n "$fips_line" ]]; then
        echo "Current setting: $fips_line"
    fi
}

# Restore from backup
fipsrestore() {
    local config_path
    config_path="$(_fips_config_path)"
    
    if [[ ! -f "$config_path" ]]; then
        echo "Error: OpenSSL configuration file not found" >&2
        return 1
    fi
    
    local backup_path="${config_path}.backup"
    if [[ ! -f "$backup_path" ]]; then
        echo "Error: No backup file found at $backup_path" >&2
        return 1
    fi
    
    if cp "$backup_path" "$config_path"; then
        echo "Configuration restored from backup: $backup_path"
        fipsstatus
    else
        echo "Error: Failed to restore from backup" >&2
        return 1
    fi
}
