import os
from dotenv import load_dotenv
from azure.storage.blob import BlobServiceClient, BlobClient, BlobProperties
import subprocess

load_dotenv()

connection_string = os.getenv('AZURE_STORAGE_CONNECTION_STRING')
mount_path = os.getenv('MOUNT_PATH')
print(f'Mount path: {mount_path}')
blob_service_client = BlobServiceClient.from_connection_string(connection_string)
source_container_name = 'opentofu-requests'
working_container_name = 'processing'
completed_container_name = 'completed'
source_container_client = blob_service_client.get_container_client(source_container_name)
working_container_client = blob_service_client.get_container_client(working_container_name)

def move_blob_to_container(
        source_blob_container_name: str,
        source_blob_props: BlobProperties, 
        destination_container_name: str) -> BlobClient:
    print(f'Copying blob {source_blob_props.name} to {destination_container_name}...')
    source_blob: BlobClient = blob_service_client.get_blob_client(source_blob_container_name, source_blob_props.name)
    destination_blob: BlobClient = blob_service_client.get_blob_client(destination_container_name, source_blob.blob_name)
    destination_blob.start_copy_from_url(source_blob.url)

    # Wait for the copy to complete
    copy_status = destination_blob.get_blob_properties().copy.status
    while copy_status != 'success':
        copy_status = destination_blob.get_blob_properties().copy.status
        print(f'Copy status: {copy_status}')
    print(f'Blob {source_blob.blob_name} copied to {destination_container_name}')
    source_blob.delete_blob()
    print(f'Blob {source_blob.blob_name} deleted from {source_container_name}')
    return destination_blob

def process_blob(destination_blob: BlobClient):
    print(f'Processing blob {destination_blob.blob_name}...')
    # Download the blob
    download_file_path = f'{mount_path}{destination_blob.blob_name}'
    with open(download_file_path, 'wb') as download_file:
        download_file.write(destination_blob.download_blob().readall())
    print(f'Blob {destination_blob.blob_name} downloaded to {download_file_path}')

    # Process the blob
    subprocess.run(['chmod', '+x', './terraform'], cwd=mount_path)
    subprocess.run(['file', './terraform', 'version'], cwd=mount_path)
    subprocess.run(['file', './terraform', 'init', mount_path], cwd=mount_path)
    subprocess.run(['file', './terraform', 'plan', mount_path], cwd=mount_path)

    print(f'Blob {destination_blob.blob_name} processed')

# Get the first blob in the source container
incoming_blobs_list = source_container_client.list_blobs()
for incoming_blob in incoming_blobs_list:
    print(f'Incoming blob: {incoming_blob.name}')
    src_blob_props = incoming_blob
    dest_blob = move_blob_to_container(source_container_name, src_blob_props, working_container_name)
    process_blob(dest_blob)
    move_blob_to_container(dest_blob.container_name, dest_blob.get_blob_properties(), completed_container_name)
    break

pending_blobs_list = working_container_client.list_blobs()
for pending_blob in pending_blobs_list:
    print(f'Pending blob: {pending_blob.name}')
    dest_blob: BlobClient = blob_service_client.get_blob_client(working_container_client.container_name, pending_blob.name)
    process_blob(dest_blob)
    move_blob_to_container(dest_blob.container_name, dest_blob.get_blob_properties(), completed_container_name)