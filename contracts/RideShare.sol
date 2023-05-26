// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;
import "./Ownable.sol";

contract RideShare is Ownable{
    // state variable
    struct Passenger {
        uint256 price;
        string state;
    }

    // state variable
    struct Ride {
        address driver;
        uint256 drivingCost;
        uint256 capacity;
        uint256 confirmedAt;
        string originAddress;
        string desAddress;
        address payable[] passengerAccts;
    }

    mapping(address => Passenger) passengers;
    Ride[] public rides;
    uint256 public rideCount;

    function createRide(
        address _driver,
        uint256 _drivingCost,
        uint256 _capacity, 
        uint256 _confirmedAt,
        string memory _originAddress,
        string memory _destAddress
    ) public {
        Ride memory newRide = Ride({
            driver: _driver,
            drivingCost: _drivingCost,
            capacity: _capacity,
            confirmedAt: _confirmedAt,
            originAddress: _originAddress,
            desAddress: _destAddress,
            passengerAccts: new address payable[](0)
        });
        rides.push(newRide);
        rideCount++;
    }

     // Function for a passenger to join a ride
    function joinRide(uint256 _rideNumber) public payable {
        Ride storage curRide = rides[_rideNumber];
        require(msg.value == curRide.drivingCost, "Insufficient payment for joinng the ride");

        Passenger memory passenger = Passenger({
            price: msg.value,
            state: "initital"
        });
        
        passengers[msg.sender] = passenger;
        curRide.passengerAccts.push(payable(msg.sender));
    }

   // Function for a passenger to confirm that they met the driver
    function confirmDriverMet(uint256 _rideNumber) public {
        
        Ride storage curRide = rides[_rideNumber];
        Passenger storage passenger = passengers[msg.sender];

        // Check if the passenger has joined the ride
        require(bytes(passenger.state).length != 0, "You haven't joined this ride");

        // Update the passenger's state to indicate that they have met the driver
        passenger.state = "driverConfirmed";
    }

    // Function for the driver to indicate that they have arrived at the destination
    function arrived(uint256 _rideNumber) public {
        Ride storage curRide = rides[_rideNumber];

        // Check if the caller is the driver of the ride
        require(msg.sender == curRide.driver, "Only driver of the ride can call this function");

        // Calculate the total payment owed to the driver by the passengers
        uint256 totalPayment = 0;
        for (uint256 i = 0; i < curRide.passengerAccts.length; i++) {
            address payable passengerAcct = curRide.passengerAccts[i];
            if(bytes(curRide.passengers[passengerAcct].state).length != 0 &&
            bytes(curRide.passengers[passengerAcct].state)[0] == "d") {
                totalPayment += curRide.passengers[passengerAcct].price;
                curRide.passengers[passengerAcct].state = "completion";
            }

            payable(curRide.driver).transfer(totalPayment);
        }
    }

    // Function for a passenger or the driver to cancel a ride
    function cancelRide(uint256 _rideNumber) public {
        Ride storage curRide = rides[_rideNumber];

        // Check if the ride is already confirmed
        require(block.timestamp <= curRide.confirmedAt, "Ride has already been confirmed");

        // Check if the caller is the driver or a passenger
        if(msg.sender == curRide.driver) {
            // If the caller is the driver, transfer the payment to the first passenger
            curRide.passengerAccts[0].transfer(curRide.drivingCost);
        } else {
            // If the caller is a passenger, refund their payment
            msg.sender.transfer(curRide.passengers[msg.sender].prices);
        }
    }
}