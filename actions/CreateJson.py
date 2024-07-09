import ssl
import json
import os
from pyVim.connect import SmartConnect, Disconnect
from pyVmomi import vim
from common.methods import set_progress
from resourcehandlers.vmware.models import VsphereResourceHandler
from utilities.events import add_server_event

def connect_to_vcenter(rh):
    """
    Connect to the vCenter server using the provided resource handler.
    """
    context = ssl._create_unverified_context()
    service_instance = SmartConnect(
        host=rh.ip,
        user=rh.serviceaccount,
        pwd=rh.servicepasswd,
        sslContext=context
    )
    return service_instance

def split_path_to_dict(path):
    """
    Split the path into a dictionary with the format {0: "level1", 1: "level2", ...}
    """
    path_parts = path.split('/')
    return {i: part for i, part in enumerate(path_parts)}

def get_folder_structure_and_vms(service_instance):
    """
    Retrieve the folder structure and VMs from the vCenter server.
    """
    content = service_instance.RetrieveContent()
    folder_structure = []

    def recursive_folder_search(folder, path=""):
        folder_info = {
            "path": split_path_to_dict(path if path else folder.name),
            "folder": folder.name,
            "uuid": folder._moId,
            "vms": []
        }

        for child in folder.childEntity:
            if isinstance(child, vim.Folder):
                child_path = f"{path}/{child.name}" if path else child.name
                folder_info["vms"].extend(recursive_folder_search(child, child_path))
            elif isinstance(child, vim.VirtualMachine):
                vm_info = {
                    "name": child.name,
                    "uuid": child.config.instanceUuid,
                    "moid": child._moId,
                    "power_state": child.runtime.powerState
                }
                folder_info["vms"].append(vm_info)

        folder_structure.append(folder_info)
        return folder_info["vms"]

    for dc in content.rootFolder.childEntity:
        if isinstance(dc, vim.Datacenter):
            recursive_folder_search(dc.vmFolder, dc.name)

    return folder_structure

def export_to_json(data, file_path):
    """
    Export data to a JSON file.
    """
    try:
        with open(file_path, 'w') as json_file:
            json.dump(data, json_file, indent=4)
        set_progress(f"Data exported to {file_path}")
    except Exception as e:
        set_progress(f"Failed to export data to JSON file: {e}")

def run(job, *args, **kwargs):
    """
    Main function to run the post-sync plugin.
    """
    set_progress("Starting VMware folder to CloudBolt group sync.")

    # Get VMware resource handlers
    vmware_resource_handlers = set()
    for rh in job.order_item.resource_handlers.all():
        if isinstance(rh.cast(), VsphereResourceHandler):
            vmware_resource_handlers.add(rh)

    if not vmware_resource_handlers:
        set_progress("No VMware resource handlers found.")
        return "SUCCESS", "No VMware resource handlers found.", ""

    folder_structure = []
    for rh in vmware_resource_handlers:
        try:
            # Connect to vCenter and get folder structure and VMs
            service_instance = connect_to_vcenter(rh)
            folder_structure.extend(get_folder_structure_and_vms(service_instance))
            Disconnect(service_instance)
            set_progress(f"Retrieved folder structure and VMs.")
        except Exception as e:
            set_progress(f"Failed to connect to vCenter or retrieve folder structure: {e}")
            continue

    # Define the file path for the JSON file in STATIC_ROOT
    json_file_path = os.path.join('/var/www/html/cloudbolt/static/collected/', 'vmware_folder_structure.json')

    # Export to JSON
    export_to_json(folder_structure, json_file_path)
    set_progress("/static-1.0/vmware_folder_structure.json")

    return "SUCCESS", "VMware folder to CloudBolt group sync completed successfully.", ""