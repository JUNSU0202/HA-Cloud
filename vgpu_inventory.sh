#!/bin/bash

# Print header
echo -e "Provider Name\tUUID\t\t\t\t\t\tTotal VGPU\tUsed VGPU\tReserved VGPU"

# Get provider list starting with gpu01_pci_, sorted by provider name
openstack resource provider list -f value | grep 'gpu01_pci_' | sort -k2 | while read uuid name rest; do
  # Fetch inventory for each provider
  inventory=$(openstack resource provider inventory list $uuid -f value | grep VGPU)

  # If VGPU inventory exists, parse the total, used, and reserved
  if [ -n "$inventory" ]; then
    total=$(echo $inventory | awk '{print $7}')
    used=$(echo $inventory | awk '{print $8}')
    reserved=$(echo $inventory | awk '{print $5}')

    # Print the result in tab-separated format
    echo -e "$name\t$uuid\t$total\t\t$used\t\t$reserved"
  else
    echo -e "$name\t$uuid\tNo VGPU\t\tNo VGPU\t\tNo VGPU"
  fi
done

