const ethers = require('ethers');

const recoverAddress = (message, signature) => {
    const recoveredAddress = ethers.verifyMessage(message, signature);
    console.log(`Recovered Address: ${recoveredAddress}`);
};

// Get the message and signature from the command line arguments
const message = process.argv[2];
const signature = process.argv[3];

if (!message || !signature) {
    console.error('Please provide a message and its signature as arguments.');
    process.exit(1);
}

recoverAddress(message, signature);