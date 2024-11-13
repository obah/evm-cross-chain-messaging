import { ethers } from "hardhat";
// import { vars } from "hardhat/config";

// const ALCHEMY_API_KEY = vars.get("ALCHEMY_API_KEY");

async function main() {
  // const provider = new ethers.JsonRpcProvider(
  //   `https://eth-sepolia.g.alchemy.com/v2/${ALCHEMY_API_KEY}`
  // );

  const HANDLER_CONTRACT_ADDR = "0x1234567890123456789012345678901234567890";

  const HANDLER_CONTRACT = await ethers.getContractAt(
    "Handler",
    HANDLER_CONTRACT_ADDR
  );

  const handleTx = await HANDLER_CONTRACT.handle();

  try {
    // Call the contract function
    // Replace 'yourFunctionName' with the actual function name
    // Add any parameters required by the function
    // const result = await HANDLER_CONTRACT.handle();
    console.log("Function call result:", result);
  } catch (error) {
    console.error("Error calling contract function:", error);
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
