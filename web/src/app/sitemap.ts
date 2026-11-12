import type { MetadataRoute } from "next";

export default function sitemap(): MetadataRoute.Sitemap {
  return [
    {
      url: "https://interestsect.com",
      changeFrequency: "weekly",
      priority: 1,
    },
    {
      url: "https://interestsect.com/login",
      changeFrequency: "monthly",
      priority: 0.3,
    },
  ];
}
