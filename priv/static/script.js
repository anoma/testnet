// import { foo } from './test.js';

//----------------------------------------------------------------------------
// Configuration

const CONFIG = {
  twitterClientId: 'RG5ZOVoydWJlZ3FOSnVTa1dDTnA6MTpjaQ', // X OAuth 2.0 Client ID
  // backendUrl: 'http://localhost:4000',
  // redirectUri: 'http://localhost:4000/index.html', // Exact match with backend
  // websocketUrl: 'ws://localhost:4000/socket/websocket',
  // backendUrl: 'https://anoma.genserver.be',
  // redirectUri: 'https://anoma.genserver.be/index.html', // Exact match with backend
  // websocketUrl: 'wss://anoma.genserver.be/socket/websocket',
  backendUrl: 'https://d4ukhw26jb5lr.cloudfront.net',
  redirectUri: 'https://d4ukhw26jb5lr.cloudfront.net/index.html', // Exact match with backend
  websocketUrl: 'wss://d4ukhw26jb5lr.cloudfront.net/socket/websocket',
};

//----------------------------------------------------------------------------
// Global variables

// the struct of the user how its represented in the backend
let currentUser = null;
let currentUserId = null;
let currentJwt = null;

//----------------------------------------------------------------------------
// Main entrypoint

document.addEventListener('DOMContentLoaded', async function () {
  // set some debug data on the webpage
  setDebugData();

  //----------------------------------------------------------------------------
  // Install callbacks on buttons

  // button to login to x.com
  const xloginBtn = document.getElementById('xloginBtn');
  xloginBtn.addEventListener('click', doXLogin);

  // button to login with metamask
  const loginBtn = document.getElementById('loginBtn');
  loginBtn.addEventListener('click', doMetaMaskLogin);

  // button to sign in to metamask
  const metamaskBtn = document.getElementById('metamaskBtn');
  metamaskBtn.addEventListener('click', connectMetamask);

  // clear all local data button
  const clearDataBtn = document.getElementById('clearDataBtn');
  clearDataBtn.addEventListener('click', cleanupData);

  // add fitcoin handler
  const addFitcoinBtn = document.getElementById('addFitcoinBtn');
  addFitcoinBtn.addEventListener('click', addFitcoin);



  //----------------------------------------------------------------------------
  // Check for existing session

  // Check if we have existing authentication data
  currentJwt = localStorage.getItem('jwt');
  currentUserId = localStorage.getItem('user_id');

  if (currentJwt && currentUserId) {
    console.log('Found existing session');
  } else {
    console.log('No existing session found');
  }

  //----------------------------------------------------------------------------
  // Check if this a redirect from X.com

  // the page is loaded after being redirected from x.com
  const urlParams = new URLSearchParams(window.location.search);
  const code = urlParams.get('code');

  if (code) {
    console.log('redirected here from x.com');
    await handleRedirect(code);
  }


  //----------------------------------------------------------------------------
  // Websocket connection

  connectWebSocket();
});

//----------------------------------------------------------------------------
// Handle the initial page load

async function doXLogin() {
  console.log('logging in on x.com');

  const codeVerifier = generateCodeVerifier();
  localStorage.setItem('twitter_code_verifier', codeVerifier);

  const codeChallenge = await generateCodeChallenge(codeVerifier);

  // create the url to authenticate with X.com
  const twitterUrl =
    `https://twitter.com/i/oauth2/authorize?` +
    `response_type=code&` +
    `client_id=${CONFIG.twitterClientId}&` +
    `redirect_uri=${encodeURIComponent(CONFIG.redirectUri)}&` +
    `scope=tweet.read%20users.read%20follows.read&` +
    `state=state&` +
    `code_challenge=${codeChallenge}&` +
    `code_challenge_method=S256`;

  // redirect to the x.com auth page
  window.location.href = twitterUrl;
}

async function handleRedirect(code) {
  console.log('handling redirect from x.com');

  // read code verified from local storage
  const codeVerifier = localStorage.getItem('twitter_code_verifier');

  // send code and code_verified to the backend to let it fetch a token for our account
  try {
    const response = await fetch(`${CONFIG.backendUrl}/api/v1/user/xauth`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${currentJwt}`,
      },
      body: JSON.stringify({ code: code, code_verifier: codeVerifier }),
    });

    if (!response.ok) {
      logMessage('/api/v1/user/auth returned an error', 'error', channel = 'messages');
      throw new Error(`HTTP error! status: ${response.status}`);
    }

    // if the request succeeded, we get back {user: .., success: true}
    const data = await response.json();

    if (data.success && data.user) {
      currentUser = data.user;
      localStorage.setItem('user_id', currentUser.id);

      currentUserId = currentUser.id;
      localStorage.setItem('user_id', currentUserId);

      updateUserData();

      // persist the backend jwt in local storage
      currentJwt = data.jwt;
      localStorage.setItem('jwt', currentJwt);

      window.history.replaceState({}, document.title, window.location.pathname);
    } else {
      throw new Error('Invalid response from server');
    }
  } catch (error) {
  } finally {
  }
}

//----------------------------------------------------------------------------
// Handle MetaMask authentication

async function doMetaMaskLogin() {
  console.log('Starting MetaMask authentication');

  if (!window.ethereum) {
    logMessage('MetaMask is not installed!', 'error', 'messages');
    return;
  }

  try {
    // Request account access
    const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' });
    const address = accounts[0];

    // Create a message to sign
    const message = `Welcome to Anoma Testnet! Sign this message to authenticate with your wallet. Address: ${address} Nonce: ${Date.now()}`;

    // Sign the message
    const signature = await window.ethereum.request({
      method: 'personal_sign',
      params: [message, address]
    });

    console.log('Message signed successfully');

    // Send signature to backend for verification
    await authenticateWithSignature(address, message, signature);

  } catch (error) {
    console.error('MetaMask authentication failed:', error);
    logMessage('MetaMask authentication failed: ' + error.message, 'error', 'messages');
  }
}

async function authenticateWithSignature(address, message, signature) {
  try {
    const response = await fetch(`${CONFIG.backendUrl}/api/v1/user/metamask-auth`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        address: address,
        message: message,
        signature: signature
      })
    });

    if (!response.ok) {
      logMessage('/api/v1/user/metamask-auth returned an error', 'error', 'messages');
      throw new Error(`HTTP error! status: ${response.status}`);
    }

    const data = await response.json();

    if (data.success && data.user) {
      currentUser = data.user;
      currentUserId = data.user.id;
      currentJwt = data.jwt;

      // Store in localStorage
      localStorage.setItem('user_id', currentUserId);
      localStorage.setItem('jwt', currentJwt);

      updateUserData();
      logMessage('Authentication successful', 'success', 'messages');
    } else {
      throw new Error('Invalid response from server');
    }
  } catch (error) {
    console.error('Authentication error:', error);
    logMessage('Authentication error: ' + error.message, 'error', 'messages');
  }
}

//----------------------------------------------------------------------------
// Fitcoin

async function addFitcoin() {
  console.log('adding 1 fitcoin');


  // send code and code_verified to the backend to let it fetch a token for our account
  try {
    const response = await fetch(`${CONFIG.backendUrl}/api/v1/fitcoin`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${currentJwt}`,
      },
      body: JSON.stringify({}),
    });

    if (!response.ok) {
      logMessage('/api/v1/fitcoin returned an error', 'error', channel = 'messages');
      throw new Error(`HTTP error! status: ${response.status}`);
    }
  } catch (error) {
    logMessage('/api/v1/fitcoin returned an error', 'error', channel = 'messages');
    throw new Error(`HTTP error! status: ${error}`);
  }
}


//----------------------------------------------------------------------------
// Websocket connection

function connectWebSocket() {
  try {
    // Create Phoenix Socket connection
    socket = new Socket(CONFIG.websocketUrl);

    // Set up WebSocket event handlers before connecting
    socket.ws = new WebSocket(CONFIG.websocketUrl);

    socket.ws.onopen = function (event) {
      logMessage('WebSocket connected', 'incoming');
      connectChannel(socket);
    };

    socket.ws.onerror = function (error) {
      logMessage('WebSocket error', 'incoming');
    };

    socket.ws.onclose = function (event) {
      logMessage('WebSocket closed', 'incoming');
    };

    socket.ws.onmessage = function (event) {
      logMessage(event.data, 'incoming');
      socket.onConnMessage(event);
    };
  } catch (error) {
    logMessage('Connection error: ' + error.message, 'error');
  }
}

function connectChannel(socket) {
  if (!currentUserId || !currentJwt) {
    logMessage('no data found to connect to the channel');
    return;
  }
  channel = socket.channel(`user:${currentUserId}`);

  // Set up channel event handlers

  channel.on('phx_reply', function (payload) {
    // if the login failed, this is the place we will see the error message
    if (payload.response.reason == 'join crashed' || payload.response.reason == 'user not found') {
      console.log('valid jwt, but user not found');
      cleanupData();
      return;
    }
    logMessage(JSON.stringify(payload), 'incoming', 'channelMessages');
    currentUser = payload.response;
    updateUserData();
  });

  channel.on('profile_update', function (payload) {
    console.log("payload", payload);
    currentUser = payload.user;
    updateUserData();
    logMessage('profile_update: ' + JSON.stringify(payload), 'incoming', 'channelMessages');
  });

  channel.on;

  channel.join(currentJwt);
}

//----------------------------------------------------------------------------
// Metamask

async function connectMetamask() {
  if (!window.ethereum) {
    showMessage('MetaMask is not installed!', 'error');
    return;
  }

  try {
    // Request account access
    const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' });
    const publicAddress = accounts[0];
    // Send the public address to the backend
    await fetch('/api/v1/user/ethereum-address', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${currentJwt}`,
      },
      body: JSON.stringify({ address: publicAddress }),
    });
    showMessage('Ethereum address sent to backend: ' + publicAddress, 'success');
  } catch (error) {
    showMessage('Error connecting wallet: ' + error.message, 'error');
  }
}

//----------------------------------------------------------------------------
// Debugging

function setDebugData() {
  const debug = document.getElementById('debugdata');
  debug.innerHTML = `
    jwt: ${localStorage.getItem('jwt')}
    user_id: ${localStorage.getItem('user_id')}
    `;
}

/*
Cleanup the data from local storage. This is done when the user tried to login
with valid jwt but the user did not exist in the backend.
*/
function cleanupData() {
  localStorage.removeItem('jwt');
  localStorage.removeItem('user_id');
  setDebugData();
}
