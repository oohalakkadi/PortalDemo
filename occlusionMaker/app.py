from flask import Flask, request, jsonify
import firebase_admin
from firebase_admin import credentials, storage
import subprocess
import os

app = Flask(__name__)

cred_path = os.path.join(os.path.dirname(__file__), 'portals-ce599-firebase-adminsdk-3ref1-2d4ce95586.json') # generated via firebase admin, in .gitignore

cred = credentials.Certificate(cred_path)
firebase_admin.initialize_app(cred, {'storageBucket': 'gs://portals-ce599.appspot.com'})

def download_file(blob_name, file_path):
    bucket = storage.bucket()
    blob = bucket.blob(blob_name)
    blob.download_to_filename(file_path)

def upload_file(file_path, blob_name):
    bucket = storage.bucket()
    blob = bucket.blob(blob_name)
    blob.upload_from_filename(file_path)

@app.route('/process_model', methods=['POST'])
def process_model():
    data = request.json
    model_path = data['model_path']
    local_input_path = "/tmp/original_model.glb"
    local_output_path = "/tmp/occlusion_scene.glb"

    download_file(model_path, local_input_path)

    blender_path = "/Applications/Blender.app/Contents/MacOS/Blender" 
    subprocess.run([
        blender_path, "--background", "--python", "generate_occlusion_mesh.py",
        "--", local_input_path, local_output_path
    ])

    # Upload the processed model back to Firebase
    upload_file(local_output_path, 'portals/occlusion_scene.glb')

    return jsonify({"status": "success", "message": "Model processed and uploaded."})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001)

