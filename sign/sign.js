const ethers = require('ethers');

// You'd typically get the private key from some secure source or configuration
// For this example, I'm using a random private key. 
// NEVER hard code your real private key in scripts.
const privateKey = '9C0257114EB9399A2985F8E75DAD7600C5D89FE3824FFA99EC1C3EB8BF3B0501';
const wallet = new ethers.Wallet(privateKey);

const signMessage = async (message) => {
    const signedMessage = await wallet.signMessage(message);
    console.log(`${signedMessage}`);
};

// Get the string argument from the command line
const messageToSign = process.argv[2];

if (!messageToSign) {
    console.error('Please provide a message to sign as an argument.');
    process.exit(1);
}

signMessage(messageToSign);