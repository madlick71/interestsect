"use client";

import { useState } from "react";

// Zeigt die Anzahl der eigenen Interessen; Klick öffnet die
// alphabetische Liste.
export default function MyInterests({ interests }: { interests: string[] }) {
  const [open, setOpen] = useState(false);

  return (
    <div className="mt-4">
      <button
        type="button"
        onClick={() => setOpen((v) => !v)}
        className="text-sm font-medium underline decoration-dotted underline-offset-4 hover:text-gray-700"
        aria-expanded={open}
      >
        Deine Interessen: {interests.length}{" "}
        <span aria-hidden>{open ? "▲" : "▼"}</span>
      </button>

      {open && (
        <ul className="mt-3 grid grid-cols-1 gap-x-6 gap-y-1 rounded-lg border bg-white p-4 text-sm sm:grid-cols-3 xl:grid-cols-5">
          {interests.map((name) => (
            <li key={name}>{name}</li>
          ))}
        </ul>
      )}
    </div>
  );
}
