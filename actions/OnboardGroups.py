import pyVmomi
import csv
from pyVmomi import vim
from resourcehandlers.vmware.pyvmomi_wrapper import get_vm_by_moid, wait_for_tasks
from resourcehandlers.vmware import pyvmomi_wrapper
from jobs.models import RecurringJob
from resources.models import Resource, ResourceType
from infrastructure.models import Environment, Server
from resourcehandlers.vcloud_director.models import VCDHandler
from resourcehandlers.vmware.models import VsphereResourceHandler
from accounts.models import UserProfile, Group
from django.contrib.auth.models import User
from servicecatalog.models import ServiceBlueprint
from tags.models import CloudBoltTag
from resourcehandlers.models import ResourceHandler



rh = ResourceHandler.objects.first()
w = rh.get_api_wrapper()
si = w._get_connection()
content = si.RetrieveContent()

tags_dict = {"CloudBoltManaged":"CloudBoltManaged"}
resourceid02 = {}

def get_obj(content, vimtype, name):
    obj = None
    container = content.viewManager.CreateContainerView(
        content.rootFolder, vimtype, True)
    for c in container.view:
        if c.name == name:
            obj = c
            break
    return obj

#vmFolder = get_obj(content,[vim.Folder],"jaryd.billesbach") ### used for testing
def vcenter_work(row):
    group=None
    #vmname=row.get('\ufeffName',None)
    vmname=row.get('Name',None)
    vmname = vmname.lower()
    vmowner=row.get('VMOwner',None)
    vmowner=vmowner.lower()
    vmid=row.get('Id',None)
    resourcepool = row.get('ResourcePool',None)
    vmfolderpath=row.get('FolderPath',None)
    if vmfolderpath:
        #group=vmfolderpath.split("\\").[2] ### This line OR the next two
        groupstring=vmfolderpath.split("\\")
        group=groupstring[2]

    if group:
        if group == "MistNet":
            group = "Engineering NDR"
        
    else:
        print("-"*25 +" Folder path without backslash "+"-"*25 +"\n", vmname, vmowner, vmid, group)

    if vmowner and vmname:
        print(vmowner,vmname)
        #find server in vCenter and Tag CloudBolt Managed
        try:
            moid = vmid.split("VirtualMachine-")[1]
            vmbyid = get_vm_by_moid(si, moid)

            if vmbyid:
                print("Found",vmbyid)
                w.update_vm_tags_in_vcenter(moid,tags_dict) ### this updates the VM with the CloudBolt tag
                
                root_folder = get_obj(content,[vim.Folder],"Engineering_Cluster")
                obj_view = content.viewManager.CreateContainerView(root_folder,[vim.Folder],True)
                vm_folders = obj_view.view
                root_folder = None
                for folder in vm_folders:
                    print(folder.name)
                    if folder.name == group:
                        group_folder = folder
                        break

                obj_view.Destroy()
                if group_folder:
                    obj_view = content.viewManager.CreateContainerView(group_folder,[vim.Folder],True)
                    vm_folders = obj_view.view
                    found = False
                    for folder in vm_folders:
                        print(folder.name)
                        if folder.name == vmowner:
                            found = True
                            break

                    if found == True:
                        target_folder = folder
                    else:
                        #create folder names vmowner
                        target_folder = group_folder.CreateFolder(vmowner)

                    obj_view.Destroy()
                    #move to VMware CloudBolt folder
                    target_folder.MoveInto([vmbyid])


                else:
                    print("-"*25 +" Group Folder Not Found "+"-"*25 +"\n", group) 

        except:
            print("$"*25+" Machine Not Found "+"-"*25 +"\n", moid)



def cloudbolt_work(row):
    group = None
    cbgroup = None
    server = None
    #vmname = row.get('\ufeffName',None)
    vmname = row.get('Name',None)
    vmname = vmname.lower()
    vmowner = row.get('VMOwner',None)
    vmowner = vmowner.lower()
    vmowner = vmowner.replace(" ","")
    vmid = row.get('Id',None)
    resourcepool = row.get('ResourcePool',None)
    vmfolderpath = row.get('FolderPath',None)

    global resourceid02

    rh = VsphereResourceHandler.objects.first()
    environment = Environment.objects.get(name='Engineering_Cluster')
	
    try:
        cbowner = UserProfile.objects.get(user__username=vmowner)
    except:
        #create owner if doesn't exist
        fname = vmowner.split(".")[0]
        lname = vmowner.split(".")[1]
        User.objects.create_user(username=vmowner,first_name=fname,last_name=lname,email=vmowner + "@logrhythm.com")
        cbowner = UserProfile.objects.get(user__username=vmowner)

    if vmfolderpath:
        #group=vmfolderpath.split("\\").[2] ### This line OR the next two
        groupstring=vmfolderpath.split("\\")
        group=groupstring[2]

    if group:
        if group == "MistNet":
            group = "Engineering NDR"
            
        try:
            cbgroup = Group.objects.get(name=group)
        except:
            print("-"*25 +" CloudBolt Group Not Found "+"-"*25 +"\n", group)
    
    if cbgroup:
        moid = vmid.split("VirtualMachine-")[1]
        try:
            vmbyid = get_vm_by_moid(si, moid)
        except:
            print("-"*25 +" VM not in vCenter "+"-"*25 +"\n", moid)
            return 1
        uuid = vmbyid.config.uuid
        try:
            server = Server.objects.get(resource_handler_svr_id=uuid,status='ACTIVE')
        except:
            svr = Server(
                status="ACTIVE",
                hostname=vmname,
                owner=cbowner,
                group=cbgroup,
                environment=environment,
                resource_handler=rh,
                resource_handler_svr_id=uuid,
            )
            svr.save()
            server = Server.objects.get(resource_handler_svr_id=uuid,status='ACTIVE')

        

        if server:
            #add label to server with old host name
            label,_ = CloudBoltTag.objects.get_or_create(name=server.hostname)
            server.tags.add(label)
            server.save()

            #create resource
            resource_type = ResourceType.objects.get(name='ENG_Deployment')
            blueprint = ServiceBlueprint.objects.get(name="ENG-Individual OS")
            
            
            res_identifier = vmowner + "-" + vmfolderpath.split("\\")[-2]

            #resource = Resource.objects.get(name=res_identifier)
            res_lookup = resourceid02.get(res_identifier, None)
            if res_lookup:
                #Use found resource
                res_id = int(res_lookup)
            else:
                resource = Resource.objects.create(name="ENG", resource_type=resource_type, lifecycle="ACTIVE", group=cbgroup, blueprint=blueprint, owner=cbowner)
                resource.name = 'ENG-ImportedDeployment-R' + str(resource.id)
                resource.save()

                resourceid02[res_identifier] = str(resource.id)
                res_id = resource.id

            resource = Resource.objects.get(id=res_id)


            #add to resource
            resource.server_set.add(server)
            resource.save()
            server.resource_id = resource.id
            #rename server in CloudBolt
            hostname = "ENG-" + cbowner.user.username + "-Imported-R" + str(resource.id) + '-S' + str(server.id)
            server.hostname = hostname
            server.save()
            task = vmbyid.Rename(hostname)
            wait_for_tasks(si, [task])
            data = [vmowner,vmname,hostname]
            filewriter.writerow(data)
    return 0
        
with open("/var/opt/cloudbolt/proserv/csv/VMsToImportToCloudBolt.csv",newline='',encoding='utf-8') as csvfile:
    reader=csv.DictReader(csvfile)
    for row in reader:
        print(row)
        vcenter_work(row)
        
with open("/var/opt/cloudbolt/proserv/csv/VMsToImportToCloudBolt-Export.csv","w",newline='',encoding='utf-8') as csvwriter:
    filewriter = csv.writer(csvwriter)
    headers = ["owner","oldName","newName"]
    filewriter.writerow(headers)

    with open("/var/opt/cloudbolt/proserv/csv/VMsToImportToCloudBolt.csv",newline='',encoding='utf-8') as csvfile:
        reader=csv.DictReader(csvfile)
        for row in reader:
                cloudbolt_work(row)

#Run a VM Sync on the vCenter resource handler            
rj = RecurringJob.objects.get(id=2)
rj.spawn_new_job()