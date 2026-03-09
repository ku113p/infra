const experience = [
  {
    role: "AI Engineer",
    company: "OnSocial",
    period: "Dec 2020 — Present",
    description:
      "Social network analytics platform for advertising agencies. Leading AI/ML integration and full-stack backend architecture as the core engineer driving the AI roadmap.",
    highlights: [
      "Architected a production-grade embedding pipeline aggregating 10M+ user profiles — consolidating variable-length content (posts, descriptions, bios) into unified dense vectors for semantic search and LLM-powered filtering at scale",
      "Integrated LLM embeddings for semantic filtering and search, improving content discovery relevance",
      "Designed and deployed data labeling pipelines and LLM evaluation workflows to ensure model quality",
      "Increased platform revenue by 30% by building automated billing with Stripe, PayPal, and Doku integrations",
      "Deployed a white-label engine enabling rapid launch of customized solutions for enterprise clients",
    ],
    tech: [
      "Python",
      "LangGraph",
      "FastAPI",
      "Celery",
      "ClickHouse",
      "MongoDB",
      "MySQL",
      "Docker",
      "Kubernetes",
    ],
  },
  {
    role: "ML Platform Engineer",
    company: "Sber Devices",
    period: "Dec 2019 — Dec 2020",
    description:
      "Built ML infrastructure for Salut, the voice assistant powering Sber\u2019s banking app ecosystem \u2014 one of the largest financial platforms in Eastern Europe.",
    highlights: [
      "Designed the end-to-end ML pipeline: data ingestion, labeling, model training, and production deployment",
      "Shipped 20+ NLU scenarios (intent recognition, entity extraction, dialog flows) expanding the assistant across banking and payments",
      "Streamlined the data collection and annotation process, cutting iteration cycles and accelerating model improvements",
    ],
    tech: ["Python", "Django", "MinIO", "Kafka"],
  },
  {
    role: "Python Developer",
    company: "Rate&Goods",
    period: "Jun 2018 — Dec 2019",
    description:
      "Social network for shoppers: product reviews, barcode-based search, and ML-powered recommendations.",
    highlights: [
      "Discovered and fixed a critical neural network bug that had served identical recommendations to every user for over a year \u2014 undetected",
      "Rebuilt the recommendation pipeline with optimized database queries, improving accuracy and response times",
      "Built analytics dashboards providing product and user insights to the business team",
    ],
    tech: ["Python", "Django", "PostgreSQL", "Celery", "Redis"],
  },
  {
    role: "Python Developer",
    company: "CheckU & Simkomat",
    period: "May 2017 — Jun 2018",
    description:
      "CheckU \u2014 KYC verification platform. Simkomat \u2014 software for hardware SIM-card vending servers with full testing lifecycle.",
    highlights: [
      "Achieved 100% test coverage through neural network integration for automated verification",
      "Improved response speed by 26% through backend optimization",
      "Built an E2E testing framework and scripts covering the full hardware-software stack",
    ],
    tech: ["Python", "Docker", "MySQL", "MongoDB", "Redis", "RabbitMQ"],
  },
];

export default experience;
