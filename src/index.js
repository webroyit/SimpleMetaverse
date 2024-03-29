import keyInput from "./keyInput.js";
import { connect, web3, contract } from './contract.js';
import UAuth from '@uauth/js'

const uauth = new UAuth({
  clientID: '',
  redirectUri: 'https://simplemetaverse.netlify.app/',
})

const ratio = window.innerWidth / window.innerHeight;
const contract_address = "0x7c53ef98d49eef0dd8f10dbfef21f97ae0434a26";

// Creating the scene
const scene = new THREE.Scene();

/* 
    1) Field of view
    2) Ratio
    3) Clipping start, where the camera is going to start rendering stuff from
    4) Clipping end
*/
const camera = new THREE.PerspectiveCamera( 75, ratio, 0.1, 1000 );

const renderer = new THREE.WebGLRenderer();     // What the user should see
renderer.setSize( window.innerWidth, window.innerHeight );
document.body.appendChild( renderer.domElement );       // Add it to the DOM

/*
    Instantiated geometry element
    1) Width
    2) Height
    3) Depth
*/
const geometry = new THREE.BoxGeometry(50, 0.1, 50);

const light = new THREE.AmbientLight(0x404040);

/* 
    Direction of the light
    1) Color
    2) Brightness Value
*/ 
const dLight = new THREE.DirectionalLight(0xffffff, 0.5);

// Apply the light
light.add(dLight);
scene.add(light);

// Instantiated material element
const material = new THREE.MeshPhongMaterial( { color: 0xffffff } );

// Create a mesh
const ground = new THREE.Mesh( geometry, material );

// Add ground to scene
scene.add( ground );

/*
    Move the camera to see the ground
    1) X
    2) Y
    3) Z
*/
camera.position.set(5, 15, 15);

// For animation
// Every seconds this function is called
function animate() {
	requestAnimationFrame( animate );   // Infinite loop

    // For Up
    if(keyInput.isPressed(38)){
        camera.position.y += 0.5;
        camera.position.x += 0.5;
    }

    // For Down
    if(keyInput.isPressed(40)){
        camera.position.y -= 0.5;
        camera.position.x -= 0.5;
    }
    
    camera.lookAt(ground.position);     // Set the camera to look at ground
	renderer.render( scene, camera );
}

async function onMint(){
    const container = document.getElementById("container")
    
    console.log("mint")
    web3.eth.getAccounts().then((accounts) => {
        contract.methods
            .mint("1")
            .send({ from: accounts[0] })
            .then((data) => {
                console.log(data)
                let link = document.createElement("a");
                link.setAttribute('href', "https://mumbai.polygonscan.com/tx/" + data.transactionHash)
                link.innerHTML = "Success"
                container.appendChild(link)
            })
    })
}

async function totalNFTs(){
    const nfts = await fetch(`https://api.covalenthq.com/v1/80001/tokens/${contract_address}/nft_token_ids/?quote-currency=USD&format=JSON&key=`);
    const { data } = await nfts.json();
    console.log(data);
    const header = document.getElementById("header");
    header.innerText = `Total NFTs minted: ${data.items.length}`;
}

async function login(){
    try {
        const login = document.getElementById("login");
        login.className = "none";

        const authorization = await uauth.loginWithPopup();
        console.log(authorization);
        const header = document.getElementById("name");
        header.innerText = authorization.idToken.sub;

        connect.then((result) => {
            console.log(result);
            result.buildings.forEach((b, index) => {
                if(index <= result.supply) {
                    const boxGeometry = new THREE.BoxGeometry(b.w, b.h, b.d);
                    const boxMaterial = new THREE.MeshPhongMaterial( { color: 0x00ff00 } );
                    const box = new THREE.Mesh( boxGeometry, boxMaterial );
                    box.position.set(b.x, b.y, b.z);
        
                    scene.add( box );
                }
            })
        });
    } catch (error) {
        console.error(error);
    }
}

document.getElementById("submit_mint").onclick = onMint;
document.getElementById("login").onclick = login;

totalNFTs();
animate();