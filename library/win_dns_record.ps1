#!powershell

# Copyright: (c) 2019, Hitachi ID Systems, Inc.
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#Requires -Module Ansible.ModuleUtils.Legacy

$ErrorActionPreference = "Stop"

$params = Parse-Args -arguments $args -supports_check_mode $true
$check_mode = Get-AnsibleParam -obj $params -name "_ansible_check_mode" -type "bool" -default $false
$diff_mode = Get-AnsibleParam -obj $params -name "_ansible_diff" -type "bool" -default $false

$name = Get-AnsibleParam -obj $params -name "name" -type "str" -failifempty $true
$state = Get-AnsibleParam -obj $params -name "state" -type "str" -default "present" -validateset "present","absent"
$ttl = Get-AnsibleParam -obj $params -name "ttl" -type "int" -default 3600
$type = Get-AnsibleParam -obj $params -name "type" -type "str" -failifempty $true -validateset "A","AAAA","CNAME","PTR"
$values = Get-AnsibleParam -obj $params -name "value" -type "list" -default @() -aliases @("values")
$zone = Get-AnsibleParam -obj $params -name "zone" -type "str" -failifempty $true
$dns_computer_name = Get-AnsibleParam -obj $params -Name "computer_name" -failifempty $false


$extra_args = @{}
if ($dns_computer_name -ne $null) {
    $extra_args.ComputerName = $dns_computer_name
}

if ($state -eq 'present')
{
    if ($values.Count -eq 0)
    {
        Fail-Json "values must be non-empty when state='present'"
    }
}
else
{
    if ($values.Count -ne 0)
    {
        Fail-Json "values must be undefined or empty when state='absent'"
    }
}


# TODO: add warning for forest minTTL override -- see https://docs.microsoft.com/en-us/windows/desktop/ad/configuration-of-ttl-limits
if ($ttl -lt 1 -or $ttl -gt 31557600)
{
    Fail-Json "ttl must be between 1 and 31557600"
}
$ttl = New-TimeSpan -Seconds $ttl


if (($type -eq 'CNAME' -or $type -eq 'PTR') -and $values -ne $null -and $values.Count -gt 0 -and $zone[-1] -ne '.')
{
    # CNAMEs and PTRs should be '.'-terminated, or record matching will fail
    $values = $values | ForEach-Object {
        if ($_ -Like "*.") { $_ } else { "$_." }
    }
}


$result = @{
    changed = $false
}


$record_argument_name = @{
    A = "IPv4Address";
    AAAA = "IPv6Address";
    CNAME = "HostNameAlias";
    # MX = "MailExchange";
    # NS = "NameServer";
    PTR = "PtrDomainName";
    # TXT = "DescriptiveText"
}[$type]


$changes = New-Object -Typename System.Collections.ArrayList


$records = Get-DnsServerResourceRecord -ZoneName $zone -Name $name -RRType $type -Node -ErrorAction:Ignore @extra_args | Sort-Object
if ($records -ne $null)
{
    # We use [Hashtable]$required_values below as a set rather than a map.
    # It provides quick lookup to test existing DNS record against. By removing
    # items as each is processed, whatever remains at the end is missing
    # content (that needs to be added).
    $required_values = @{}
    foreach ($value in $values)
    {
        $required_values[$value.ToString()] = $null
    }

    foreach ($record in $records)
    {
        $record_value = $record.RecordData.$record_argument_name.ToString()

        if ($required_values.ContainsKey($record_value))
        {
            # This record matches one of the values; but does it match the TTL?
            if ($record.TimeToLive -ne $ttl)
            {
                $new_record = $record.Clone()
                $new_record.TimeToLive = $ttl
                Set-DnsServerResourceRecord -ZoneName $zone -OldInputObject $record -NewInputObject $new_record -WhatIf:$check_mode @extra_args

                $changes += "-[$zone] $($record.HostName) $($record.TimeToLive.TotalSeconds) $type $record_value`n"
                $changes += "+[$zone] $($record.HostName) $($ttl.TotalSeconds) $type $record_value`n"
                $result.changed = $true
            }

            # Cross this one off the list, so we don't try adding it later
            $required_values.Remove($record_value)
        }
        else
        {
            # This record doesn't match any of the values, and must be removed
            $record | Remove-DnsServerResourceRecord -ZoneName $zone -Force -WhatIf:$check_mode @extra_args

            $changes += "-[$zone] $($record.HostName) $($record.TimeToLive.TotalSeconds) $type $record_value`n"
            $result.changed = $true
        }
    }

    # Whatever is left in $required_values needs to be added
    $values = $required_values.Keys
}


if ($values -ne $null -and $values.Count -gt 0)
{
    foreach ($value in $values)
    {
        $splat_args = @{ $type = $true; $record_argument_name = $value }
        Add-DnsServerResourceRecord -ZoneName $zone -Name $name -AllowUpdateAny -TimeToLive $ttl @splat_args -WhatIf:$check_mode @extra_args

        $changes += "+[$zone] $name $($ttl.TotalSeconds) $type $value`n"
    }

    $result.changed = $true
}


if ($diff_mode) {
    $result.diff = @{ prepared = ($changes -Join '') }
}


Exit-Json -obj $result
