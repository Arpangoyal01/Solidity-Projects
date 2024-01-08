// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract CrowdFunding{
    mapping(address=>uint) public contributors;
    address public manager;
    uint public minimumContribution;
    uint public deadline;
    uint public target;
    uint public raisedAmount;
    uint public noOfContributors;

    //No. of funding request by random peoples for accidents, event, etc

    struct Request{
        string description;
        address payable recipient;
        uint value;
        bool completed;
        uint noOfVoters;
        mapping(address=>bool) voters;
    }

    //No. of request count

    mapping(uint=>Request) public requests;
    uint public numRequests;

    //Event execution for funds contribution
    
    constructor(uint _target,uint _deadline){
        target = _target;
        deadline= block.timestamp+_deadline; //10sec + 3600 (60*60)
        minimumContribution=100 wei;
        manager = msg.sender;
    }

    // contributors will descied to send random amount of ether

    function sendEth() public payable{
        require(block.timestamp < deadline, "Deadline has over");
        require(msg.value>= minimumContribution, "Minimum Contribution is not met");

        //Is it priviously contributor or new contributor

        if(contributors[msg.sender]==0){
            noOfContributors++;
        }
        contributors[msg.sender]+=msg.value;
        raisedAmount+=msg.value;
    }
    
    //for check contract balance

    function getContractBalance() public view returns(uint){
        return address(this).balance;
    }

    //contributor can demand for refund after only cross deadline and target not completed

    function refund() public{
        require(block.timestamp>deadline && raisedAmount<target,"You are not eligilble for refund");
        require(contributors[msg.sender]>0, "You are not the contributor "); //dout about if contributor value found 0 then how to send them error
        address payable user = payable(msg.sender);
        user.transfer(contributors[msg.sender]);
        contributors[msg.sender]=0;
    }

    // creat request

    modifier onlyManager(){
        require(msg.sender==manager,"only can call this funtion");
        _;
    }
    function creatRequests(string memory _description, address payable _recipient, uint _value) public onlyManager{
        Request storage newRequest = requests[numRequests]; //when make mapping in structure then cant use of "memory" keyword
        numRequests++;
        newRequest.description=_description;
        newRequest.recipient=_recipient;
        newRequest.value=_value;
        newRequest.completed=false;
        newRequest.noOfVoters=0;
    }

    //for voting proccess

    function voteRequest(uint _requestNo) public{
        require(contributors[msg.sender]>0,"You must be Contributor");
        Request storage thisRequest=requests[_requestNo];
        require(thisRequest.voters[msg.sender]==false, "You have already voted");
        thisRequest.voters[msg.sender]=true;
        thisRequest.noOfVoters++;
    }

    //checking how much peoples vote favour in particular request

    function makePayment(uint _requestNo) public onlyManager{
        require(raisedAmount>=target);
        Request storage thisRequest=requests[_requestNo];
        require(thisRequest.completed==false,"the request has been completed");
        require(thisRequest.noOfVoters > noOfContributors/2,"Majority dose not support");
        thisRequest.recipient.transfer(thisRequest.value);
        thisRequest.completed=true;
    }
}
