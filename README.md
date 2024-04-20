## GVSU-AR
A basic augmented reality iOS app which allows users to place and modify GVSU inspired 3D models.


## OVERVIEW
This iOS application is an augmented reality experience that allows users to interact with Grand Valley State University (GVSU) inspired 3D models in the world around them. Whether you're on campus or elsewhere, immerse yourself in GVSU's environment by placing virtual objects in your surroundings through your iOS device's camera.

## TECHNOLOGIES USED
This application mainly relies on 2 graphics-based technologies

1. Blender - Used to create the 3D models such as the GVSU sign and logo. These models are then converted to .usdz files to be used within our app.

2. Apple RealityKit/ARKit - This provided Apple framework simplifies the process of working with 3D assets, animations, and interactions within the AR environment. In this application, it is responsible for the rendering and manipulation of our GVSU assets.

## Running the Project

# 1. Clone the Repository
- Open Terminal on your Mac.
- Navigate to the directory where you want to store the project.
- Use the following command to clone the repository:
  git clone https://github.com/owencairns/GVSU-AR

# 2. Open in XCode
- Open XCode and navigate to where the project is stored
- Alternatively, if XCode CLI tools are install, within the terminal run:
  xed .

# 3. Install and Run on iPhone
- In the project settings -> Signing & Capabilities, set the team
- Connect your phone to the computer
- Select your phone from the list of devices at the top of the XCode window
- Run the application, this should begin building on your phone
- On the iPhone, go to settings -> general -> VPN & Device Management, click on your Apple ID and trust

## Demo

https://youtu.be/QZXJ4Wzo33c
