const fs = require("fs");
const {
  Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell,
  Header, Footer, AlignmentType, LevelFormat, HeadingLevel,
  BorderStyle, WidthType, ShadingType, PageNumber, PageBreak
} = require("docx");

// Colors
const BRAND_BLUE = "1B3A5C";
const BRAND_TEAL = "0D9488";
const BRAND_GOLD = "B8860B";
const BRAND_RED = "DC2626";
const ACCENT_LIGHT = "F0F9FF";
const GRAY = "6B7280";
const LIGHT_GRAY = "F3F4F6";
const WHITE = "FFFFFF";
const BLACK = "000000";

const noBorder = { style: BorderStyle.NONE, size: 0, color: WHITE };
const noBorders = { top: noBorder, bottom: noBorder, left: noBorder, right: noBorder };
const thinBorder = { style: BorderStyle.SINGLE, size: 1, color: "D1D5DB" };
const thinBorders = { top: thinBorder, bottom: thinBorder, left: thinBorder, right: thinBorder };

function spacer(size = 200) {
  return new Paragraph({ spacing: { before: size, after: 0 }, children: [] });
}

function sectionTitle(text) {
  return new Paragraph({
    spacing: { before: 360, after: 200 },
    border: { bottom: { style: BorderStyle.SINGLE, size: 3, color: BRAND_TEAL, space: 8 } },
    children: [new TextRun({ text: text.toUpperCase(), bold: true, size: 28, color: BRAND_BLUE, font: "Arial" })],
  });
}

function bulletItem(text, bold_prefix = null) {
  const children = [];
  if (bold_prefix) {
    children.push(new TextRun({ text: bold_prefix, bold: true, size: 22, font: "Arial", color: "374151" }));
    children.push(new TextRun({ text: text, size: 22, font: "Arial", color: "374151" }));
  } else {
    children.push(new TextRun({ text, size: 22, font: "Arial", color: "374151" }));
  }
  return new Paragraph({
    numbering: { reference: "bullets", level: 0 },
    spacing: { before: 60, after: 60 },
    children,
  });
}

function bodyText(text, opts = {}) {
  return new Paragraph({
    spacing: { before: 80, after: 80 },
    alignment: opts.center ? AlignmentType.CENTER : AlignmentType.LEFT,
    children: [new TextRun({
      text,
      size: opts.size || 22,
      font: "Arial",
      color: opts.color || "374151",
      bold: opts.bold || false,
      italics: opts.italic || false,
    })],
  });
}

// Cover page elements
const coverTitle = new Paragraph({
  alignment: AlignmentType.CENTER,
  spacing: { before: 3000, after: 200 },
  children: [new TextRun({ text: "NeuroNav", bold: true, size: 72, color: BRAND_BLUE, font: "Arial" })],
});

const coverSubtitle = new Paragraph({
  alignment: AlignmentType.CENTER,
  spacing: { before: 100, after: 100 },
  children: [new TextRun({ text: "Adaptive Daily Living Assistant", size: 36, color: BRAND_TEAL, font: "Arial" })],
});

const coverTagline = new Paragraph({
  alignment: AlignmentType.CENTER,
  spacing: { before: 200, after: 100 },
  children: [new TextRun({ text: "Empowering independence for adults with cognitive disabilities", size: 24, color: GRAY, font: "Arial", italics: true })],
});

const coverLine = new Paragraph({
  alignment: AlignmentType.CENTER,
  spacing: { before: 400, after: 200 },
  border: { bottom: { style: BorderStyle.SINGLE, size: 4, color: BRAND_TEAL, space: 1 } },
  children: [],
});

const coverCompany = new Paragraph({
  alignment: AlignmentType.CENTER,
  spacing: { before: 200, after: 60 },
  children: [new TextRun({ text: "The Neuronavs", bold: true, size: 28, color: BRAND_BLUE, font: "Arial" })],
});

const coverEvent = new Paragraph({
  alignment: AlignmentType.CENTER,
  spacing: { before: 60, after: 60 },
  children: [new TextRun({ text: "Tech4Good 2026", size: 24, color: BRAND_GOLD, font: "Arial", bold: true })],
});

const coverDate = new Paragraph({
  alignment: AlignmentType.CENTER,
  spacing: { before: 60, after: 60 },
  children: [new TextRun({ text: "Business Pitch", size: 22, color: GRAY, font: "Arial" })],
});

// Pricing table
const pricingHeaderRow = new TableRow({
  tableHeader: true,
  children: ["Plan", "Price", "Features"].map((text, i) => {
    const widths = [2200, 2200, 4960];
    return new TableCell({
      width: { size: widths[i], type: WidthType.DXA },
      borders: thinBorders,
      shading: { fill: BRAND_BLUE, type: ShadingType.CLEAR },
      margins: { top: 80, bottom: 80, left: 120, right: 120 },
      children: [new Paragraph({
        alignment: AlignmentType.CENTER,
        children: [new TextRun({ text, bold: true, size: 20, color: WHITE, font: "Arial" })],
      })],
    });
  }),
});

const pricingRows = [
  ["Basic", "Free", "1 patient, 3 routines, basic tracking"],
  ["Standard", "$4.99/mo", "Unlimited routines, caregiver linking, safety zones"],
  ["Professional", "$14.99/mo", "Multi-patient management, analytics, priority support"],
  ["Institutional", "Custom", "Bulk licensing for hospitals and care facilities"],
].map((row, idx) =>
  new TableRow({
    children: row.map((text, i) => {
      const widths = [2200, 2200, 4960];
      return new TableCell({
        width: { size: widths[i], type: WidthType.DXA },
        borders: thinBorders,
        shading: { fill: idx % 2 === 0 ? LIGHT_GRAY : WHITE, type: ShadingType.CLEAR },
        margins: { top: 80, bottom: 80, left: 120, right: 120 },
        children: [new Paragraph({
          alignment: i < 2 ? AlignmentType.CENTER : AlignmentType.LEFT,
          children: [new TextRun({ text, size: 20, font: "Arial", bold: i === 0, color: i === 0 ? BRAND_BLUE : "374151" })],
        })],
      });
    }),
  })
);

const pricingTable = new Table({
  width: { size: 9360, type: WidthType.DXA },
  columnWidths: [2200, 2200, 4960],
  rows: [pricingHeaderRow, ...pricingRows],
});

// Tech stack table
const techHeaderRow = new TableRow({
  tableHeader: true,
  children: ["Component", "Technology"].map((text, i) => {
    const widths = [3000, 6360];
    return new TableCell({
      width: { size: widths[i], type: WidthType.DXA },
      borders: thinBorders,
      shading: { fill: BRAND_TEAL, type: ShadingType.CLEAR },
      margins: { top: 80, bottom: 80, left: 120, right: 120 },
      children: [new Paragraph({
        children: [new TextRun({ text, bold: true, size: 20, color: WHITE, font: "Arial" })],
      })],
    });
  }),
});

const techData = [
  ["iOS App", "Swift 5.9+, SwiftUI, iOS 17+"],
  ["Apple Watch", "watchOS 10+, WatchConnectivity"],
  ["Backend", "NestJS + TypeORM + PostgreSQL"],
  ["Database", "Supabase (PostgreSQL + Auth + Real-time)"],
  ["Dashboard", "Next.js 15 + Tailwind CSS"],
  ["Widgets", "WidgetKit + Live Activities + App Intents (Siri)"],
];

const techRows = techData.map((row, idx) =>
  new TableRow({
    children: row.map((text, i) => {
      const widths = [3000, 6360];
      return new TableCell({
        width: { size: widths[i], type: WidthType.DXA },
        borders: thinBorders,
        shading: { fill: idx % 2 === 0 ? LIGHT_GRAY : WHITE, type: ShadingType.CLEAR },
        margins: { top: 80, bottom: 80, left: 120, right: 120 },
        children: [new Paragraph({
          children: [new TextRun({ text, size: 20, font: "Arial", bold: i === 0, color: "374151" })],
        })],
      });
    }),
  })
);

const techTable = new Table({
  width: { size: 9360, type: WidthType.DXA },
  columnWidths: [3000, 6360],
  rows: [techHeaderRow, ...techRows],
});

// Build document
const doc = new Document({
  styles: {
    default: {
      document: { run: { font: "Arial", size: 22 } },
    },
    paragraphStyles: [
      {
        id: "Heading1", name: "Heading 1", basedOn: "Normal", next: "Normal", quickFormat: true,
        run: { size: 32, bold: true, font: "Arial", color: BRAND_BLUE },
        paragraph: { spacing: { before: 360, after: 200 }, outlineLevel: 0 },
      },
      {
        id: "Heading2", name: "Heading 2", basedOn: "Normal", next: "Normal", quickFormat: true,
        run: { size: 26, bold: true, font: "Arial", color: BRAND_TEAL },
        paragraph: { spacing: { before: 240, after: 160 }, outlineLevel: 1 },
      },
    ],
  },
  numbering: {
    config: [
      {
        reference: "bullets",
        levels: [{
          level: 0, format: LevelFormat.BULLET, text: "\u2022", alignment: AlignmentType.LEFT,
          style: { paragraph: { indent: { left: 720, hanging: 360 } } },
        }],
      },
      {
        reference: "numbers",
        levels: [{
          level: 0, format: LevelFormat.DECIMAL, text: "%1.", alignment: AlignmentType.LEFT,
          style: { paragraph: { indent: { left: 720, hanging: 360 } } },
        }],
      },
    ],
  },
  sections: [
    // COVER PAGE
    {
      properties: {
        page: {
          size: { width: 12240, height: 15840 },
          margin: { top: 1440, right: 1440, bottom: 1440, left: 1440 },
        },
      },
      children: [coverTitle, coverSubtitle, coverTagline, coverLine, coverCompany, coverEvent, coverDate],
    },
    // CONTENT PAGES
    {
      properties: {
        page: {
          size: { width: 12240, height: 15840 },
          margin: { top: 1440, right: 1440, bottom: 1440, left: 1440 },
        },
      },
      headers: {
        default: new Header({
          children: [new Paragraph({
            border: { bottom: { style: BorderStyle.SINGLE, size: 2, color: BRAND_TEAL, space: 4 } },
            children: [
              new TextRun({ text: "NeuroNav", bold: true, size: 18, color: BRAND_BLUE, font: "Arial" }),
              new TextRun({ text: "  |  Business Pitch  |  Tech4Good 2026", size: 18, color: GRAY, font: "Arial" }),
            ],
          })],
        }),
      },
      footers: {
        default: new Footer({
          children: [new Paragraph({
            alignment: AlignmentType.CENTER,
            children: [
              new TextRun({ text: "The Neuronavs  |  ", size: 16, color: GRAY, font: "Arial" }),
              new TextRun({ text: "Page ", size: 16, color: GRAY, font: "Arial" }),
              new TextRun({ children: [PageNumber.CURRENT], size: 16, color: GRAY, font: "Arial" }),
            ],
          })],
        }),
      },
      children: [
        // === EXECUTIVE SUMMARY ===
        sectionTitle("Executive Summary"),
        bodyText("NeuroNav is an adaptive daily living assistant designed for adults with cognitive disabilities. Our platform provides step-by-step guided routines that automatically adjust complexity based on real-time user performance, empowering patients to achieve greater independence in their daily lives."),
        spacer(100),
        bodyText("Built by The Neuronavs, our solution bridges the gap between caregivers and patients through a connected ecosystem that includes an iOS app, Apple Watch companion, web dashboard, and a proprietary adaptive engine with 5 complexity levels."),
        spacer(100),
        bodyText("We are seeking to launch at Tech4Good 2026 as a social impact technology that transforms how cognitive rehabilitation and daily living support are delivered."),

        // === THE PROBLEM ===
        sectionTitle("The Problem"),
        bodyText("Adults with cognitive disabilities face significant challenges performing everyday tasks independently. Current solutions are either too generic, require constant human supervision, or fail to adapt to individual cognitive abilities."),
        spacer(80),
        bulletItem("Over 15% of the global population lives with some form of disability"),
        bulletItem("Caregivers spend an average of 24+ hours per week providing unpaid assistance"),
        bulletItem("Existing assistive apps treat all users the same, ignoring varying cognitive levels"),
        bulletItem("No current solution combines real-time adaptation with multi-sensory feedback"),
        bulletItem("Families lack visibility into their loved ones\u2019 daily progress and safety"),

        // === OUR SOLUTION ===
        sectionTitle("Our Solution"),
        bodyText("NeuroNav delivers a comprehensive platform that adapts to each user\u2019s unique cognitive profile:"),
        spacer(80),
        bulletItem(" \u2014 Task complexity adjusts automatically based on real-time performance metrics", "Adaptive Engine"),
        bulletItem(" \u2014 Cooking, hygiene, medication, laundry, transit, shopping, and more", "Guided Routines"),
        bulletItem(" \u2014 Detects when a user is stuck and provides automatic help prompts via TTS", "Stall Detection"),
        bulletItem(" \u2014 Caregivers create routines and monitor progress; families observe safely", "Caregiver Linking"),
        bulletItem(" \u2014 Voice guidance, Apple Watch haptics, and clear visual cues", "Multi-Sensory Feedback"),
        bulletItem(" \u2014 Geofencing safety zones, emergency contacts, and medication reminders", "Safety Features"),

        // === VALUE PROPOSITION ===
        sectionTitle("Value Proposition"),
        bodyText("For patients:", { bold: true }),
        bulletItem("Greater independence in daily activities without constant supervision"),
        bulletItem("Personalized difficulty that grows with the user\u2019s abilities"),
        bulletItem("Multi-sensory support that meets diverse cognitive needs"),
        spacer(80),
        bodyText("For caregivers:", { bold: true }),
        bulletItem("Remote routine creation and real-time progress monitoring"),
        bulletItem("Reduced supervision burden with automated stall detection and assistance"),
        bulletItem("Data-driven insights into patient performance trends"),
        spacer(80),
        bodyText("For families:", { bold: true }),
        bulletItem("Peace of mind through safety zones and emergency alerts"),
        bulletItem("Visibility into daily progress without interfering with care"),
        bulletItem("Secure, privacy-first data handling with Row-Level Security"),

        // === TARGET MARKET ===
        sectionTitle("Target Market"),
        bulletItem("Adults with acquired brain injuries, intellectual disabilities, or neurodegenerative conditions", "Primary Users: "),
        bulletItem("Occupational therapists, home care aides, and support workers", "Professional Caregivers: "),
        bulletItem("Parents, siblings, and partners who want to monitor progress", "Family Members: "),
        bulletItem("Hospitals, clinics, and rehabilitation centers", "Healthcare Institutions: "),
        bulletItem("Foundations and support groups serving disability communities", "Disability Organizations: "),

        // PAGE BREAK
        new Paragraph({ children: [new PageBreak()] }),

        // === BUSINESS MODEL ===
        sectionTitle("Business Model"),
        bodyText("NeuroNav operates on a freemium subscription model with institutional licensing:"),
        spacer(100),
        pricingTable,
        spacer(100),
        bodyText("Additional revenue streams:", { bold: true }),
        bulletItem("Government grants and assistive technology funding programs"),
        bulletItem("Insurance company partnerships for assistive technology coverage"),
        bulletItem("Anonymized aggregate data insights for healthcare research (with consent)"),

        // === COMPETITIVE ADVANTAGE ===
        sectionTitle("Competitive Advantage"),
        new Paragraph({
          numbering: { reference: "numbers", level: 0 },
          spacing: { before: 80, after: 80 },
          children: [
            new TextRun({ text: "Adaptive Complexity Engine", bold: true, size: 22, font: "Arial", color: BRAND_BLUE }),
            new TextRun({ text: " \u2014 No other app adjusts task difficulty in real-time based on user performance across 5 levels", size: 22, font: "Arial", color: "374151" }),
          ],
        }),
        new Paragraph({
          numbering: { reference: "numbers", level: 0 },
          spacing: { before: 80, after: 80 },
          children: [
            new TextRun({ text: "Multi-Sensory Feedback", bold: true, size: 22, font: "Arial", color: BRAND_BLUE }),
            new TextRun({ text: " \u2014 Combines TTS voice guidance, Apple Watch haptics, and clear visual cues for maximum accessibility", size: 22, font: "Arial", color: "374151" }),
          ],
        }),
        new Paragraph({
          numbering: { reference: "numbers", level: 0 },
          spacing: { before: 80, after: 80 },
          children: [
            new TextRun({ text: "Complete Caregiver Ecosystem", bold: true, size: 22, font: "Arial", color: BRAND_BLUE }),
            new TextRun({ text: " \u2014 Full platform connecting patients, caregivers, and families with role-based access", size: 22, font: "Arial", color: "374151" }),
          ],
        }),
        new Paragraph({
          numbering: { reference: "numbers", level: 0 },
          spacing: { before: 80, after: 80 },
          children: [
            new TextRun({ text: "Apple Watch Integration", bold: true, size: 22, font: "Arial", color: BRAND_BLUE }),
            new TextRun({ text: " \u2014 Wrist-based step guidance with haptic prompts and health monitoring", size: 22, font: "Arial", color: "374151" }),
          ],
        }),
        new Paragraph({
          numbering: { reference: "numbers", level: 0 },
          spacing: { before: 80, after: 80 },
          children: [
            new TextRun({ text: "Privacy-First Architecture", bold: true, size: 22, font: "Arial", color: BRAND_BLUE }),
            new TextRun({ text: " \u2014 Row-Level Security in Supabase ensures every user\u2019s data is protected", size: 22, font: "Arial", color: "374151" }),
          ],
        }),

        // === GO-TO-MARKET STRATEGY ===
        sectionTitle("Go-To-Market Strategy"),
        bodyText("Phase 1 \u2014 Launch (Q1-Q2 2026):", { bold: true }),
        bulletItem("Launch on Apple App Store with iOS + watchOS support"),
        bulletItem("Partner with 3-5 rehabilitation centers for pilot testing"),
        bulletItem("Present at Tech4Good 2026 for visibility and early adopter acquisition"),
        spacer(80),
        bodyText("Phase 2 \u2014 Growth (Q3-Q4 2026):", { bold: true }),
        bulletItem("Expand to Android via Flutter cross-platform build"),
        bulletItem("Launch web dashboard for institutional caregivers"),
        bulletItem("Onboard disability organizations as distribution partners"),
        spacer(80),
        bodyText("Phase 3 \u2014 Scale (2027):", { bold: true }),
        bulletItem("Institutional licensing for hospitals and care facilities"),
        bulletItem("Apply for government assistive technology grants"),
        bulletItem("Explore insurance company partnerships for coverage"),

        // === TECHNOLOGY ===
        sectionTitle("Technology Stack"),
        techTable,

        // === KEY PARTNERSHIPS ===
        spacer(200),
        sectionTitle("Key Partnerships"),
        bulletItem("Hospitals and rehabilitation centers working with cognitive disability patients"),
        bulletItem("Disability organizations and nonprofits connecting us with end users"),
        bulletItem("Apple (iOS, watchOS, WidgetKit ecosystem) and Supabase (backend infrastructure)"),
        bulletItem("Universities and research centers for clinical validation"),
        bulletItem("Occupational therapists who recommend and validate the platform"),
        bulletItem("Government health agencies funding assistive technology programs"),

        // === TEAM ===
        sectionTitle("The Team"),
        bodyText("The Neuronavs is a mission-driven team passionate about using technology to create social impact. Our expertise spans:"),
        spacer(80),
        bulletItem("Native iOS and watchOS development (Swift, SwiftUI)"),
        bulletItem("Backend engineering (NestJS, TypeORM, PostgreSQL, Supabase)"),
        bulletItem("Accessible UX/UI design for cognitive disability contexts"),
        bulletItem("Cross-platform mobile development (Flutter)"),
        bulletItem("Healthcare technology and adaptive systems research"),

        // === CLOSING ===
        spacer(400),
        new Paragraph({
          alignment: AlignmentType.CENTER,
          border: { top: { style: BorderStyle.SINGLE, size: 3, color: BRAND_TEAL, space: 12 } },
          spacing: { before: 400, after: 100 },
          children: [new TextRun({ text: "NeuroNav", bold: true, size: 36, color: BRAND_BLUE, font: "Arial" })],
        }),
        new Paragraph({
          alignment: AlignmentType.CENTER,
          spacing: { before: 80, after: 80 },
          children: [new TextRun({ text: "Empowering independence through adaptive technology", italics: true, size: 24, color: BRAND_TEAL, font: "Arial" })],
        }),
        new Paragraph({
          alignment: AlignmentType.CENTER,
          spacing: { before: 80, after: 80 },
          children: [new TextRun({ text: "Tech4Good 2026", bold: true, size: 22, color: BRAND_GOLD, font: "Arial" })],
        }),
      ],
    },
  ],
});

Packer.toBuffer(doc).then(buffer => {
  fs.writeFileSync("/Users/salvador/Desktop/Apps Kirks/Proyecto2/NeuroNav_Business_Pitch.docx", buffer);
  console.log("Business Pitch saved to: /Users/salvador/Desktop/Apps Kirks/Proyecto2/NeuroNav_Business_Pitch.docx");
});
