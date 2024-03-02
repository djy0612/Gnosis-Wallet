// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "../common/SelfAuthorized.sol";

/// @title Fallback Manager - A contract that manages fallback calls made to this contract
/// @author Richard Meissner - <richard@gnosis.pm>
contract FallbackManager is SelfAuthorized {
    event ChangedFallbackHandler(address handler); //事件，当回退函数发生改变时会触发该事件

    // keccak256("fallback_manager.handler.address")
    bytes32 internal constant FALLBACK_HANDLER_STORAGE_SLOT = 0x6c9a6c4a39284e37ed1cf53d337577d14212a4870fb976a4366c693b939918d5;
    //定义存储插槽的位置

    function internalSetFallbackHandler(address handler) internal { //内部设置回退函数，将回退函数的地址存储在插槽中
        bytes32 slot = FALLBACK_HANDLER_STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, handler) //存储函数  SLOAD 读取函数
        }
    }

    /// @dev Allows to add a contract to handle fallback calls.
    ///      Only fallback calls without value and with data will be forwarded.
    ///      This can only be done via a Safe transaction.
    /// @param handler contract to handle fallbacks calls.
    function setFallbackHandler(address handler) public authorized {  //授权地址设置回退函数
        internalSetFallbackHandler(handler);    //调用内部处理函数
        emit ChangedFallbackHandler(handler);  //触发事件，它将会记录在区块链上的交易日志中
    }

    // solhint-disable-next-line payable-fallback,no-complex-fallback
    fallback() external { //回退函数，当发送eth没有接收函数或者没有匹配到合约调用时触发，如果没有则交易回退
        bytes32 slot = FALLBACK_HANDLER_STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let handler := sload(slot)  //获取回退处理器合约地址
            if iszero(handler) {    //如果地址为零则立即返回
                return(0, 0)    //return(0, 0) 是一个特殊的语法，用于在函数执行完成后立即返回，并且不返回任何数据。
            }
            calldatacopy(0, 0, calldatasize())  //将调用数据复制到合约内存起始位置
            // 第一个参数 0 表示目标位置，即将数据复制到内存的起始位置。第二个参数 0 表示源数据的位置，即从调用数据的起始位置开始复制。
            // The msg.sender address is shifted to the left by 12 bytes to remove the padding
            // Then the address without padding is stored right after the calldata
            mstore(calldatasize(), shl(96, caller()))
            //将调用者的地址存储在内存数据后，需要将数据进行左移12个字节，因为address类型为20字节，mstore存储的是32字节，左移在右侧填零补充
            // Add 20 bytes for the address appended add the end
            let success := call(gas(), handler, 0, 0, add(calldatasize(), 20), 0, 0)
            // 使用 call 指令调用回退函数处理器。这里使用 gas() 函数获取剩余的 gas，handler 是回退函数处理器的地址，
            //前两个 0 表示发送的以太币数量和发送的数据的起始地址（这里没有发送以太币），add(calldatasize(), 20) 是数据的长度，0, 0 表示输出参数的地址和长度
            //calldatasize()返回的是调用数据的长度，我们还需要调用者的地址，因此再次基础上+20
            returndatacopy(0, 0, returndatasize())
            //将返回数据复制到内存中
            if iszero(success) {
                revert(0, returndatasize()) //0代表内存地址，返回从0开始到returndatasize大小的信息
                //如果回退函数处理失败，则回滚当前调用，回滚到函数调用之前，并将返回数据作为错误信息。
            }
            return(0, returndatasize())
            //成功执行时，返回数据
        }
    }
}
