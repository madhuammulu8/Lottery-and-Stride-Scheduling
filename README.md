# Table Of Contents:
   * [Scheduling in Operating System](#Scheduling-in-Operating-Systems)
   * [Scheduling Explained](#Scheduling-Explained)
      * [Lottery Scheduling](#Lottery-Scheduling)
        * [Random Generator](#Random-Generator)
        * [Counting Total Tickets](#Counting-Total-Tickets)
        * [Lottery scheduling Logic](#Lottery-scheduling-Logic)
      * [Stride Scheduling](#Stride-Scheduling)
        * [Explained](#Explained)
       

Scheduling in Operating Systems
----------------------------
----------------------------

## Scheduling Explained:

Scheduling is the process of selecting a process from a ready queue

Lottery Scheduling:
----------------------------
Functions Used: Random Generator, Total Tickets.

### Random Generator:

Lottery scheduling uses Random scheduling Hence we are using the code that is provided in the lab2 document for the generation of the random values and we pass the total number of the tickets to find the random values.

### Counting Total Tickets:

This function helps in calculating the total number of tickets that can be used here. We run a loop if the process is in a running state we increment the total tickets counter and display the results.

### Lottery scheduling Logic:

In Lottery scheduling, we are finding the lottery number that we use to schedule from the total number of tickets generated, we will check the value of the current ticket iteratively by sending in the for loop if the value of the lottery is less than the tickets than we will add a counter and keep the process in running states and this will help us in finding the number of tickets it has been scheduled to run. 

## Stride Scheduling:

In stride scheduling the largest assigned value we are using is 5000 from the lab instructions and we are calculating the current stride value and also initialize the minimum value which will help us for stride scheduling, By comparing the minimum value with the current stride we are able to find which one to scheduled in further and if min is greater than zero we are incrementing the current stride value(Basically doubling the value) and it keeps the process in running state and we can increment the ticks count which helps in finding the no of times it has been scheduled to run


## Lab2 Video Link: 
https://www.youtube.com/watch?v=4c7P9LWAwoc
