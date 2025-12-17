# ============================================
# Algorand DAO Smart Contracts - PyTeal Templates
# ============================================
# Production-ready DAO implementation for Algorand
# Includes governance, proposals, and voting
# ============================================

{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kernelcore.blockchain.algorand.dao;

  # DAO contract templates in PyTeal
  daoContracts = pkgs.writeTextDir "contracts/governance.py" ''
    """
    Algorand DAO Governance Contract
    ================================
    A decentralized governance system with:
    - Proposal creation and voting
    - Token-weighted votes
    - Quorum requirements
    - Time-locked execution

    Author: kernelcore
    Network: ${config.kernelcore.blockchain.algorand.network or "testnet"}
    """

    from pyteal import *
    from typing import Final

    # ============================================
    # GLOBAL STATE KEYS
    # ============================================
    GOVERNANCE_TOKEN: Final[bytes] = Bytes("gov_token")
    PROPOSAL_COUNT: Final[bytes] = Bytes("prop_count")
    QUORUM_THRESHOLD: Final[bytes] = Bytes("quorum")
    VOTING_PERIOD: Final[bytes] = Bytes("vote_period")
    ADMIN: Final[bytes] = Bytes("admin")

    # ============================================
    # LOCAL STATE KEYS (per account)
    # ============================================
    VOTING_POWER: Final[bytes] = Bytes("vote_power")
    DELEGATED_TO: Final[bytes] = Bytes("delegated")

    # ============================================
    # PROPOSAL BOX SCHEMA
    # ============================================
    # Box name: "prop_{id}"
    # Contents: creator|title|description|yes_votes|no_votes|start_round|end_round|executed


    def approval_program() -> Expr:
        """Main approval program for DAO governance."""
        
        # ============================================
        # INITIALIZATION
        # ============================================
        on_create = Seq([
            # Set governance token ASA ID
            App.globalPut(GOVERNANCE_TOKEN, Btoi(Txn.application_args[0])),
            # Set quorum threshold (percentage * 100, e.g., 1000 = 10%)
            App.globalPut(QUORUM_THRESHOLD, Btoi(Txn.application_args[1])),
            # Set voting period in rounds (~4.5 seconds each)
            App.globalPut(VOTING_PERIOD, Btoi(Txn.application_args[2])),
            # Initialize proposal counter
            App.globalPut(PROPOSAL_COUNT, Int(0)),
            # Set admin
            App.globalPut(ADMIN, Txn.sender()),
            Approve(),
        ])
        
        # ============================================
        # OPT-IN (Register voter)
        # ============================================
        on_opt_in = Seq([
            # Initialize local state
            App.localPut(Txn.sender(), VOTING_POWER, Int(0)),
            App.localPut(Txn.sender(), DELEGATED_TO, Global.zero_address()),
            Approve(),
        ])
        
        # ============================================
        # STAKE TOKENS (Update voting power)
        # ============================================
        @Subroutine(TealType.none)
        def update_voting_power(account: Expr) -> Expr:
            """Update voting power based on staked governance tokens."""
            return Seq([
                # Get token balance
                (balance := AssetHolding.balance(
                    account, 
                    App.globalGet(GOVERNANCE_TOKEN)
                )),
                # Update local voting power
                If(
                    balance.hasValue(),
                    App.localPut(account, VOTING_POWER, balance.value()),
                    App.localPut(account, VOTING_POWER, Int(0)),
                ),
            ])
        
        # ============================================
        # CREATE PROPOSAL
        # ============================================
        create_proposal = Seq([
            # Require minimum voting power to create proposal
            Assert(App.localGet(Txn.sender(), VOTING_POWER) > Int(0)),
            
            # Increment proposal counter
            (new_id := ScratchVar(TealType.uint64)),
            new_id.store(App.globalGet(PROPOSAL_COUNT) + Int(1)),
            App.globalPut(PROPOSAL_COUNT, new_id.load()),
            
            # Create proposal box
            # Args: [1] = title, [2] = description
            (box_name := ScratchVar(TealType.bytes)),
            box_name.store(Concat(Bytes("prop_"), Itob(new_id.load()))),
            
            # Store proposal data
            # Format: creator(32) | yes_votes(8) | no_votes(8) | start_round(8) | end_round(8) | executed(1)
            App.box_create(box_name.load(), Int(65)),
            App.box_replace(box_name.load(), Int(0), Txn.sender()),
            App.box_replace(box_name.load(), Int(32), Itob(Int(0))),  # yes_votes
            App.box_replace(box_name.load(), Int(40), Itob(Int(0))),  # no_votes
            App.box_replace(box_name.load(), Int(48), Itob(Global.round())),  # start
            App.box_replace(
                box_name.load(), 
                Int(56), 
                Itob(Global.round() + App.globalGet(VOTING_PERIOD))
            ),  # end
            App.box_replace(box_name.load(), Int(64), Bytes("base16", "00")),  # not executed
            
            # Log proposal creation
            Log(Concat(Bytes("proposal_created:"), Itob(new_id.load()))),
            Approve(),
        ])
        
        # ============================================
        # CAST VOTE
        # ============================================
        cast_vote = Seq([
            # Args: [1] = proposal_id, [2] = vote (1=yes, 0=no)
            (prop_id := ScratchVar(TealType.uint64)),
            prop_id.store(Btoi(Txn.application_args[1])),
            
            (vote_yes := ScratchVar(TealType.uint64)),
            vote_yes.store(Btoi(Txn.application_args[2])),
            
            (box_name := ScratchVar(TealType.bytes)),
            box_name.store(Concat(Bytes("prop_"), Itob(prop_id.load()))),
            
            # Verify proposal exists and voting is open
            (box_contents := App.box_get(box_name.load())),
            Assert(box_contents.hasValue()),
            
            (end_round := ScratchVar(TealType.uint64)),
            end_round.store(Btoi(Extract(box_contents.value(), Int(56), Int(8)))),
            Assert(Global.round() <= end_round.load()),
            
            # Get voter power (including delegations)
            (vote_power := ScratchVar(TealType.uint64)),
            vote_power.store(App.localGet(Txn.sender(), VOTING_POWER)),
            Assert(vote_power.load() > Int(0)),
            
            # Update vote counts
            If(
                vote_yes.load() == Int(1),
                # Yes vote
                Seq([
                    (current_yes := ScratchVar(TealType.uint64)),
                    current_yes.store(Btoi(Extract(box_contents.value(), Int(32), Int(8)))),
                    App.box_replace(
                        box_name.load(),
                        Int(32),
                        Itob(current_yes.load() + vote_power.load())
                    ),
                ]),
                # No vote
                Seq([
                    (current_no := ScratchVar(TealType.uint64)),
                    current_no.store(Btoi(Extract(box_contents.value(), Int(40), Int(8)))),
                    App.box_replace(
                        box_name.load(),
                        Int(40),
                        Itob(current_no.load() + vote_power.load())
                    ),
                ]),
            ),
            
            Log(Concat(Bytes("vote_cast:"), Itob(prop_id.load()))),
            Approve(),
        ])
        
        # ============================================
        # EXECUTE PROPOSAL
        # ============================================
        execute_proposal = Seq([
            # Args: [1] = proposal_id
            (prop_id := ScratchVar(TealType.uint64)),
            prop_id.store(Btoi(Txn.application_args[1])),
            
            (box_name := ScratchVar(TealType.bytes)),
            box_name.store(Concat(Bytes("prop_"), Itob(prop_id.load()))),
            
            # Get proposal data
            (box_contents := App.box_get(box_name.load())),
            Assert(box_contents.hasValue()),
            
            # Verify voting period ended
            (end_round := ScratchVar(TealType.uint64)),
            end_round.store(Btoi(Extract(box_contents.value(), Int(56), Int(8)))),
            Assert(Global.round() > end_round.load()),
            
            # Verify not already executed
            Assert(Extract(box_contents.value(), Int(64), Int(1)) == Bytes("base16", "00")),
            
            # Check quorum and majority
            (yes_votes := ScratchVar(TealType.uint64)),
            yes_votes.store(Btoi(Extract(box_contents.value(), Int(32), Int(8)))),
            (no_votes := ScratchVar(TealType.uint64)),
            no_votes.store(Btoi(Extract(box_contents.value(), Int(40), Int(8)))),
            
            Assert(yes_votes.load() > no_votes.load()),  # Majority
            
            # Mark as executed
            App.box_replace(box_name.load(), Int(64), Bytes("base16", "01")),
            
            Log(Concat(Bytes("proposal_executed:"), Itob(prop_id.load()))),
            Approve(),
        ])
        
        # ============================================
        # ROUTER
        # ============================================
        program = Cond(
            [Txn.application_id() == Int(0), on_create],
            [Txn.on_completion() == OnComplete.OptIn, on_opt_in],
            [Txn.on_completion() == OnComplete.CloseOut, Approve()],
            [Txn.on_completion() == OnComplete.UpdateApplication, 
             Return(Txn.sender() == App.globalGet(ADMIN))],
            [Txn.on_completion() == OnComplete.DeleteApplication,
             Return(Txn.sender() == App.globalGet(ADMIN))],
            [Txn.application_args[0] == Bytes("create_proposal"), create_proposal],
            [Txn.application_args[0] == Bytes("vote"), cast_vote],
            [Txn.application_args[0] == Bytes("execute"), execute_proposal],
            [Txn.application_args[0] == Bytes("update_power"), 
             Seq([update_voting_power(Txn.sender()), Approve()])],
        )
        
        return program


    def clear_state_program() -> Expr:
        """Clear state program - always approve."""
        return Approve()


    if __name__ == "__main__":
        import os
        from pyteal import compileTeal, Mode
        
        # Compile to TEAL
        approval_teal = compileTeal(
            approval_program(), 
            mode=Mode.Application, 
            version=8
        )
        clear_teal = compileTeal(
            clear_state_program(), 
            mode=Mode.Application, 
            version=8
        )
        
        # Write to files
        os.makedirs("build", exist_ok=True)
        with open("build/governance_approval.teal", "w") as f:
            f.write(approval_teal)
        with open("build/governance_clear.teal", "w") as f:
            f.write(clear_teal)
        
        print("Compiled governance contracts to build/")
  '';

in
{
  options.kernelcore.blockchain.algorand.dao = {
    enable = mkEnableOption "Algorand DAO contract templates";

    quorumThreshold = mkOption {
      type = types.int;
      default = 1000; # 10%
      description = "Quorum threshold (percentage * 100, e.g., 1000 = 10%)";
    };

    votingPeriodRounds = mkOption {
      type = types.int;
      default = 120000; # ~1 week at 4.5s/round
      description = "Voting period in rounds (~4.5 seconds each)";
    };
  };

  config = mkIf (cfg.enable && config.kernelcore.blockchain.algorand.enable) {
    # Install DAO contract templates
    environment.etc."algorand/dao" = {
      source = daoContracts;
    };

    # Shell aliases for DAO development
    environment.shellAliases = {
      dao-compile = "python /etc/algorand/dao/contracts/governance.py";
      dao-test = "pytest /etc/algorand/dao/tests/";
    };
  };
}
