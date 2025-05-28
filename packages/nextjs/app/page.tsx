"use client";

import { useState } from "react";
import Link from "next/link";
import type { NextPage } from "next";
import { parseUnits } from "viem";
import { useAccount } from "wagmi";
import { BugAntIcon, MagnifyingGlassIcon } from "@heroicons/react/24/outline";
import { Address } from "~~/components/scaffold-eth";
import { InputBase } from "~~/components/scaffold-eth";
import {
  useDeployedContractInfo,
  useScaffoldReadContract,
  useScaffoldWatchContractEvent,
  useScaffoldWriteContract,
} from "~~/hooks/scaffold-eth";

const Home: NextPage = () => {
  const { address: connectedAddress } = useAccount();
  const [amount, setAmount] = useState("");

  /** Get contract info */
  const { data: crowdfundingContract } = useDeployedContractInfo({
    contractName: "Crowdfunding",
  });

  /** Read Contract */
  // const { data } = useScaffoldReadContract({
  //   contractName: "Crowdfunding",
  //   functionName: "startTime",
  // })
  const { data: decimals } = useScaffoldReadContract({
    contractName: "FakeUSDC",
    functionName: "decimals",
  });
  const { data: allowance } = useScaffoldReadContract({
    contractName: "FakeUSDC",
    functionName: "allowance",
    args: [connectedAddress, crowdfundingContract?.address],
  });

  /** Write Contract */
  const { writeContractAsync } = useScaffoldWriteContract({ contractName: "Crowdfunding" });
  const { writeContractAsync: writeFakeUSDCContractAsync } = useScaffoldWriteContract({
    contractName: "FakeUSDC",
  });
  // await writeContractAsync({
  //   functionName: "donate",
  //   args: [1000000000000000000n],
  // })

  /** Watch Contract Event */
  useScaffoldWatchContractEvent({
    contractName: "Crowdfunding",
    eventName: "NewDonation",
    onLogs: logs => {
      logs.map(log => {
        const { donor, amount, totalDonations } = log.args;
        console.log("NewDonation", {
          donor,
          amount,
          totalDonations,
        });
      });
    },
  });

  /** Retrieve history of events */
  // const { data: events } = useScaffoldEventHistory({
  //   contractName: "Crowdfunding",
  //   eventName: "NewDonation",
  //   fromBlock: 124124123n,
  //   filters: {
  //     donor: connectedAddress,
  //   },
  //   blockData: true,
  //   transactionData: true,
  //   receiptData: true,
  // });

  const donate = async () => {
    if (!decimals || allowance === undefined) return;
    // Step 1: Convert the amount to the correct decimals
    const parsedAmount = parseUnits(amount, decimals);

    // Step 2: Check the allowance
    console.log("ALLOWANCE", allowance);

    // Step 3: Approve the contract to spend the tokens if allowance < amount to spend
    if (allowance < parsedAmount) {
      await writeFakeUSDCContractAsync({
        functionName: "approve",
        args: [crowdfundingContract?.address, parsedAmount],
      });
    }

    // Step 4: Call the donate function
    await writeContractAsync({
      functionName: "donate",
      args: [parsedAmount],
    });
  };

  return (
    <>
      <div className="flex items-center flex-col grow pt-10">
        <div className="px-5">
          <h1 className="text-center">
            <span className="block text-2xl mb-2">Welcome to</span>
            <span className="block text-4xl font-bold">Scaffold-ETH 2</span>
          </h1>
          <div className="flex justify-center items-center space-x-2 flex-col">
            <p className="my-2 font-medium">Connected Address:</p>
            <Address address={connectedAddress} />
            <InputBase onChange={setAmount} value={amount} placeholder="Amount" />
            <button className="btn btn-sm" onClick={() => donate()}>
              Donate
            </button>
          </div>

          <p className="text-center text-lg">
            Get started by editing{" "}
            <code className="italic bg-base-300 text-base font-bold max-w-full break-words break-all inline-block">
              packages/nextjs/app/page.tsx
            </code>
          </p>
          <p className="text-center text-lg">
            Edit your smart contract{" "}
            <code className="italic bg-base-300 text-base font-bold max-w-full break-words break-all inline-block">
              YourContract.sol
            </code>{" "}
            in{" "}
            <code className="italic bg-base-300 text-base font-bold max-w-full break-words break-all inline-block">
              packages/hardhat/contracts
            </code>
          </p>
        </div>

        <div className="grow bg-base-300 w-full mt-16 px-8 py-12">
          <div className="flex justify-center items-center gap-12 flex-col md:flex-row">
            <div className="flex flex-col bg-base-100 px-10 py-10 text-center items-center max-w-xs rounded-3xl">
              <BugAntIcon className="h-8 w-8 fill-secondary" />
              <p>
                Tinker with your smart contract using the{" "}
                <Link href="/debug" passHref className="link">
                  Debug Contracts
                </Link>{" "}
                tab.
              </p>
            </div>
            <div className="flex flex-col bg-base-100 px-10 py-10 text-center items-center max-w-xs rounded-3xl">
              <MagnifyingGlassIcon className="h-8 w-8 fill-secondary" />
              <p>
                Explore your local transactions with the{" "}
                <Link href="/blockexplorer" passHref className="link">
                  Block Explorer
                </Link>{" "}
                tab.
              </p>
            </div>
          </div>
        </div>
      </div>
    </>
  );
};

export default Home;
