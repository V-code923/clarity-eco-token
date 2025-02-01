import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Ensure that users can register projects",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    
    let block = chain.mineBlock([
      Tx.contractCall(
        "eco-token",
        "register-project",
        [
          types.ascii("Green Initiative"),
          types.ascii("Planting trees in urban areas")
        ],
        wallet_1.address
      )
    ]);
    
    assertEquals(block.receipts.length, 1);
    assertEquals(block.height, 2);
    block.receipts[0].result.expectOk().expectUint(1);
  },
});

Clarinet.test({
  name: "Ensure that only project owner can update metrics",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    const wallet_2 = accounts.get("wallet_2")!;
    
    let block = chain.mineBlock([
      Tx.contractCall(
        "eco-token",
        "register-project",
        [
          types.ascii("Green Initiative"),
          types.ascii("Planting trees in urban areas")
        ],
        wallet_1.address
      ),
      Tx.contractCall(
        "eco-token",
        "update-metrics",
        [types.uint(1), types.uint(100), types.uint(50), types.uint(200)],
        wallet_2.address
      )
    ]);
    
    assertEquals(block.receipts.length, 2);
    block.receipts[1].result.expectErr();
  },
});

Clarinet.test({
  name: "Ensure that only contract owner can verify projects and mint rewards",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    const wallet_1 = accounts.get("wallet_1")!;
    
    let block = chain.mineBlock([
      Tx.contractCall(
        "eco-token",
        "verify-project",
        [types.uint(1)],
        wallet_1.address
      )
    ]);
    
    assertEquals(block.receipts.length, 1);
    block.receipts[0].result.expectErr();
  },
});
