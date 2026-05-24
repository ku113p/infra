const projects = [
  {
    name: "CryoPay",
    description:
      "Crypto payment platform on Optimism and Arbitrum (USDT ERC-20). Rust/Axum backend running three concurrent Tokio tasks: REST API, blockchain monitor daemon streaming on-chain events via ethers-rs, and a Telegram notification bot. Includes a sliding-window rate limiter tuned to Infura credit costs per RPC method, webhook delivery with retries, and automated Docker CI/CD to GHCR.",
    tech: ["Rust", "Axum", "ethers-rs", "Solidity", "React", "PostgreSQL", "Redis", "Docker"],
    links: [
      { label: "Open App", url: "https://pay.syncapp.tech" },
      {
        label: "GitHub",
        url: "https://github.com/digitalscyther/cryo-pay",
        icon: "github",
      },
    ],
  },
  {
    name: "Crypto Assets",
    description:
      "DeFi portfolio tracker for managing token balances, protocol allocations, and analytics. Lightweight HTMX interface with real-time server-side rendering.",
    tech: ["Rust", "Axum", "HTMX", "Docker"],
    links: [
      { label: "Open App", url: "https://assets.crypto.syncapp.tech" },
      {
        label: "GitHub",
        url: "https://github.com/ku113p/crypto-assets",
        icon: "github",
      },
    ],
  },
  {
    name: "Interview",
    description:
      "Technical interviews are broken \u2014 scripted questions miss the real story. This platform uses AI to map professional experience through genuine multi-turn conversation, surfacing insights that static resumes can\u2019t. Built with LangGraph agent orchestration, vector database retrieval, and an automated LLM evaluation pipeline.",
    tech: ["Python", "FastAPI", "LangGraph", "RAG", "SQLite", "Docker"],
    links: [
      { label: "Promo", url: "https://promo.interview.syncapp.tech" },
      {
        label: "GitHub",
        url: "https://github.com/ku113p/interview",
        icon: "github",
      },
    ],
  },
  {
    name: "Tools Platform",
    description:
      "What if an LLM could shorten URLs, publish pages, and send messages through a single interface? Three production Rust microservices behind an MCP aggregator, giving AI agents real tools they can call autonomously.",
    tech: ["Rust", "Axum", "Redis", "PostgreSQL", "MCP", "Docker"],
    links: [
      {
        label: "GitHub",
        url: "https://github.com/ku113p/tools-mcp",
        icon: "github",
      },
    ],
    subProjects: [
      {
        name: "Short Links",
        description: "URL shortener microservice.",
        github: "https://github.com/ku113p/short-links",
      },
      {
        name: "Landing Pages",
        description: "HTML page hosting microservice.",
        github: "https://github.com/ku113p/landing-pages",
      },
      {
        name: "Message",
        description: "Contact form API microservice.",
        github: "https://github.com/ku113p/message",
      },
    ],
  },
  {
    name: "Price Alert Bot",
    description:
      "Telegram bot for cryptocurrency price alerts. Monitors prices via the CoinMarketCap API and sends notifications when user-defined thresholds are triggered.",
    tech: ["Go", "PostgreSQL", "PgBouncer", "Docker", "Telegram API"],
    links: [
      {
        label: "Open in Telegram",
        url: "https://t.me/token_price_signal_bot",
        icon: "telegram",
      },
      {
        label: "GitHub",
        url: "https://github.com/ku113p/price-alert-bot",
        icon: "github",
      },
    ],
  },
];

export default projects;
