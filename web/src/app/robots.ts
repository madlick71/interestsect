import type { MetadataRoute } from "next";

// Öffentlich sind nur / und /login; alle anderen Routen
// leiten auf den Login um und sind für Crawler irrelevant.
export default function robots(): MetadataRoute.Robots {
  return {
    rules: [
      {
        userAgent: "*",
        allow: "/",
        disallow: ["/home", "/interests", "/map", "/profile", "/api/", "/auth/"],
      },
    ],
    sitemap: "https://interestsect.com/sitemap.xml",
  };
}
