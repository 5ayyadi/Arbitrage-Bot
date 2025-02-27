# Arbitrage Bot

A fully functional arbitrage bot. This project is still under development.

## Table of Contents
- [Introduction](#introduction)
- [Features](#features)
- [Technologies Used](#technologies-used)
- [Installation](#installation)
- [Usage](#usage)
- [Deployment History](#deployment-history)
- [Contributing](#contributing)
- [License](#license)

## Introduction
The Arbitrage Bot is designed to exploit price differences of the same asset on different exchanges. This project aims to automate the arbitrage process to maximize profits.

## Features
- Monitors multiple exchanges for price differences
- Executes trades automatically
- Supports UniswapV2 integration
- Supports multiple blockchain platforms

## Technologies Used
- **Solidity:** 99.4% - Smart contracts
- **Python:** 0.6% - Scripting and automation

## Installation
1. Clone the repository:
    ```bash
    git clone https://github.com/5ayyadi/Arbitrage-Bot.git
    ```
2. Navigate to the project directory:
    ```bash
    cd Arbitrage-Bot
    ```
3. Install dependencies:
    ```bash
    pip install -r requirements.txt
    ```

## Usage
1. Configure your environment variables:
    ```bash
    cp .env.example .env
    ```
    Edit the `.env` file with your API keys and other necessary configurations.

2. Compile and deploy the smart contracts:
    ```bash
    truffle compile
    truffle migrate
    ```

3. Run the bot:
    ```bash
    python bot.py
    ```

## Deployment History
- Fantom

## Contributing
Contributions are welcome! Please fork the repository and create a pull request.
