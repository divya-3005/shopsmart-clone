# ShopSmart - Project Explanation

## 1. Architecture
The ShopSmart application follows a logical separation of concerns via a modern client-server architecture:
- **Frontend (Client)**: Built with React and Vite. It serves as the presentation layer responsible for the UI, state management, and user interactions.
- **Backend (Server)**: Built with Node.js and Express. It serves as the core API layer, handling business logic, data processing, and serving interactions requested by the frontend.

## 2. Workflow
We have established a rigorous CI/CD pipeline using GitHub Actions:
- **Continuous Integration**: On every `push` and `pull_request` to the main branch, automated workflows run to install dependencies, execute linting checks, and execute all test suites (Frontend Vitest, Backend Jest).
- **Continuous Deployment**: A secondary GitHub Action workflow is configured to deploy the application systematically to an AWS EC2 instance using SSH capabilities, automating repository updates and restarting deployment services (e.g., using PM2).

## 3. Design Decisions
- **Monorepo Structure**: The application is organized in a single repository with distinct `client` and `server` directories. This improves tracking of full-stack changes across commits and ensures synchronicity between front-end capabilities and back-end APIs.
- **Testing Layers**: We implemented a layered testing suite prioritizing fast, isolated unit tests mapped directly to utilities/components and slower, broad-scope integration and End-to-End (E2E) routines ensuring high reliability in production code. 
- **Idempotency Practices**: Local development setup scripts natively employ idempotent syntax (e.g., `mkdir -p`, `touch -a`) avoiding failure states and reducing developer friction when commands are repetitively executed.

## 4. Challenges
- **Aligning Disparate Frameworks**: Coordinating separate pipelines for a Vite/React application seamlessly with a NodeJS/Express backend into a unified workflow without causing pipeline collision errors was complex.
- **Automated Deployment Security**: Injecting AWS PEM files securely into a deployment pipeline via GitHub Secrets without leaking highly-sensitive data or disrupting the agent runner required strict adherence to environment management best practices.
