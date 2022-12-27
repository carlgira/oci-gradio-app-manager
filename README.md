# OCI Gradio App Manager

Terraform script to create a GPU machine to host a configurable set of gradio huggingface spaces. 

It's possible select those spaces using JSON file (gradio-apps.json). You need to set an app name, the git repo url, and requirements and dependencies if necesary. The script will handle the installation of everything and will serve the apps on port 8000 on nginx web server.

For this script I decided to add three spaces: (the limit is the amount of memory that the GPU can handle)

- **Anime GAN:** Face portrait in anime style.
- **Whisper:** Whisper is a general-purpose speech recognition model. It is trained on a large dataset of diverse audio and is also a multi-task model that can perform multilingual speech recognition as well as speech translation and language identification.
- **Riffusion:** Riffusion is a latent text-to-image diffusion model capable of generating spectrogram images given any text input. These spectrograms can be converted into audio clips.

## Requirements

- Terraform
- ssh-keygen

## Configuration

1. Follow the instructions to add the authentication to your tenant https://medium.com/@carlgira/install-oci-cli-and-configure-a-default-profile-802cc61abd4f.

2. Clone this repository
```
git clone https://github.com/carlgira/oci-gradio-app-manager
```

3. Set three variables in your path. 
- The tenancy OCID, 
- The comparment OCID where the instance will be created.
- The "Region Identifier" of region of your tenancy. https://docs.oracle.com/en-us/iaas/Content/General/Concepts/regions.htm

```
export TF_VAR_tenancy_ocid='<tenancy-ocid>'
export TF_VAR_compartment_ocid='<comparment-ocid>'
export TF_VAR_region='<home-region>'
```

4. Execute the script generate-keys.sh to generate private key to access the instance
```
sh generate-keys.sh
```

5. *(optional)* Configure the json file with other gradio apps.
```json
{
    "appName": "whisper",
    "appUrl": "https://huggingface.co/spaces/openai/whisper",
    "requirements": ["transformers","git+https://github.com/openai/whisper.git"],
    "Osdependencies": "ffmpeg",
    "enviroment" {
        "HF_TOKEN": "token",
        "OTHER_URL": "http://localhost"
    }
}
```

- **appName:** Name of the app, used as identifier and for the final url.
- **appUrl:** The git repo of the gradio app. 
- **requirements:** If there is problem with the original requirements.txt, or one of the dependencies is set for a specific not supported OS, you can change the requirements of the app.
- **Osdependencies:** Set of ubuntu OS dependencies if the app needs something aditional.
- **enviroment** : Set of key value pair, for aditional configuration of the gradio app. 

## Build
To build simply execute the next commands. 
```
terraform init
terraform plan
terraform apply
```

## Post configuration
To test the apps it's necessary to create a ssh tunel to the port 8000 (the output of the terraform script will give the ssh full command so you only need to copy and paste)

```
ssh -i server.key -L 8000:localhost:8000 ubuntu@<instance-public-ip>
```

## Test
Make sure to have the ssh tunnel open to test the three apps. The apps are on the next urls:

- http://localhost:8000/anime-gan/
- http://localhost:8000/whisper/
- http://localhost:8000/riffusion-demo/

## Clean
To delete the instance execute.
```
terraform destroy
```

## References
- Anime Gan https://huggingface.co/spaces/akhaliq/AnimeGANv2
- Whisper https://huggingface.co/spaces/openai/whisper
- Spectrogram to Music https://huggingface.co/spaces/carlgira/spectrogram-to-music
