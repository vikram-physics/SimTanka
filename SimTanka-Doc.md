Here is the Swift Markdown conversion of the SimTankaVC.swift file:

## Main model for simulations using rainfall data obtained via Visual Crossing API

This file defines the main model for simulating rainwater harvesting systems with covered storage tank in Swift. It uses the Markdown format for documentation comments.

**Components:**

* `SimTankaVC`: The main model class for simulations.
* `EstimateResult`: A struct for storing tank size and annual success rate.
* `DailyRainVC`: A class for representing daily rainfall records.

**SimTankaVC Class:**

This class manages the simulation of rainwater harvesting systems. It has the following features:

* Stores and manages user-defined input (runoff, catch area, tank size, daily demands).
* Retrieves daily rainfall data from Core Data.
* Estimates the reliability of the system for different tank sizes.
* Provides suggestions for optimizing tank size based on budget and reliability.

**Key Functions:**

* `PerformanceForTankSizes(myTanka:)`: Simulates performance for different tank sizes and updates UI.
* `ProbabilityOfSuccess(myTanka:)`: Calculates the probability of success for a given tank size.
* `DailyWaterHarvestedM3(day:month:year:runOff:catchAreaM2:)`: Calculates the water harvested on a specific day.
* `TankSizesForBudget(myTanka:)`: Simulates performance for different tank sizes within budget and suggests optimal size.
* `suggestTankSize(results:)`: Analyzes simulation results and provides suggestions for tank size optimization.
* `EstimateReliabilityOfUsersRWHS(myTanka:)`: Estimates the reliability of the user's current system.

**Notes:**

* The code uses asynchronous tasks for performing simulations and updating UI.
* Core Data is used to store daily rainfall records.
* Various helper functions are used for date calculations and data manipulation.

I hope this conversion is helpful! Let me know if you have any other questions.
