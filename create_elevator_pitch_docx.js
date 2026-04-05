const fs = require("fs");
const {
  Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell, ImageRun,
  Header, Footer, AlignmentType, LevelFormat, HeadingLevel,
  BorderStyle, WidthType, ShadingType, PageNumber, PageBreak
} = require("docx");

const BRAND_BLUE = "1B3A5C";
const BRAND_TEAL = "0D9488";
const BRAND_GOLD = "B8860B";
const GRAY = "6B7280";
const LIGHT_GRAY = "F3F4F6";
const WHITE = "FFFFFF";

const noBorder = { style: BorderStyle.NONE, size: 0, color: WHITE };
const noBorders = { top: noBorder, bottom: noBorder, left: noBorder, right: noBorder };
const thinBorder = { style: BorderStyle.SINGLE, size: 1, color: "D1D5DB" };
const thinBorders = { top: thinBorder, bottom: thinBorder, left: thinBorder, right: thinBorder };

function spacer(size = 200) {
  return new Paragraph({ spacing: { before: size, after: 0 }, children: [] });
}

function sectionBlock(label, timing, scriptText, color) {
  return [
    // Section label row
    new Table({
      width: { size: 9360, type: WidthType.DXA },
      columnWidths: [6800, 2560],
      rows: [
        new TableRow({
          children: [
            new TableCell({
              width: { size: 6800, type: WidthType.DXA },
              borders: noBorders,
              shading: { fill: color, type: ShadingType.CLEAR },
              margins: { top: 100, bottom: 100, left: 200, right: 120 },
              children: [new Paragraph({
                children: [new TextRun({ text: label, bold: true, size: 26, color: WHITE, font: "Arial" })],
              })],
            }),
            new TableCell({
              width: { size: 2560, type: WidthType.DXA },
              borders: noBorders,
              shading: { fill: color, type: ShadingType.CLEAR },
              margins: { top: 100, bottom: 100, left: 120, right: 200 },
              children: [new Paragraph({
                alignment: AlignmentType.RIGHT,
                children: [new TextRun({ text: timing, size: 22, color: WHITE, font: "Arial" })],
              })],
            }),
          ],
        }),
      ],
    }),
    spacer(80),
    // Script text
    new Paragraph({
      spacing: { before: 0, after: 160 },
      indent: { left: 200, right: 200 },
      children: [new TextRun({ text: scriptText, size: 24, font: "Arial", color: "1F2937", italics: true })],
    }),
    spacer(120),
  ];
}

const doc = new Document({
  styles: {
    default: { document: { run: { font: "Arial", size: 22 } } },
    paragraphStyles: [
      {
        id: "Heading1", name: "Heading 1", basedOn: "Normal", next: "Normal", quickFormat: true,
        run: { size: 32, bold: true, font: "Arial", color: BRAND_BLUE },
        paragraph: { spacing: { before: 360, after: 200 }, outlineLevel: 0 },
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
      children: [
        new Paragraph({
          alignment: AlignmentType.CENTER,
          spacing: { before: 1600, after: 200 },
          children: [new ImageRun({
            type: "png",
            data: fs.readFileSync("/Users/salvador/Desktop/Apps Kirks/Proyecto2/neuronav_logo.png"),
            transformation: { width: 180, height: 180 },
            altText: { title: "NeuroNav Logo", description: "Brain with heart icon in blue and green", name: "NeuroNav Logo" },
          })],
        }),
        new Paragraph({
          alignment: AlignmentType.CENTER,
          spacing: { before: 200, after: 200 },
          children: [new TextRun({ text: "NeuroNav", bold: true, size: 72, color: BRAND_BLUE, font: "Arial" })],
        }),
        new Paragraph({
          alignment: AlignmentType.CENTER,
          spacing: { before: 100, after: 100 },
          children: [new TextRun({ text: "Elevator Pitch Script", size: 36, color: BRAND_TEAL, font: "Arial" })],
        }),
        new Paragraph({
          alignment: AlignmentType.CENTER,
          spacing: { before: 80, after: 80 },
          children: [new TextRun({ text: "Adaptive Daily Living Assistant for Adults with Cognitive Disabilities", size: 22, color: GRAY, font: "Arial", italics: true })],
        }),
        new Paragraph({
          alignment: AlignmentType.CENTER,
          spacing: { before: 400, after: 200 },
          border: { bottom: { style: BorderStyle.SINGLE, size: 4, color: BRAND_TEAL, space: 1 } },
          children: [],
        }),
        new Paragraph({
          alignment: AlignmentType.CENTER,
          spacing: { before: 300, after: 60 },
          children: [new TextRun({ text: "CARA Format  |  1 Minute  |  Tech4Good 2026", bold: true, size: 22, color: BRAND_GOLD, font: "Arial" })],
        }),
        spacer(300),
        new Paragraph({
          alignment: AlignmentType.CENTER,
          spacing: { before: 60, after: 40 },
          children: [new TextRun({ text: "The Neuronavs", bold: true, size: 28, color: BRAND_BLUE, font: "Arial" })],
        }),
        spacer(100),
        ...[
          "Santiago Hern\u00e1ndez Balderas",
          "Salvador Adri\u00e1n Mart\u00ednez",
          "Edgar",
          "Hiram",
          "Mauricio Ch\u00e1vez",
        ].map(name => new Paragraph({
          alignment: AlignmentType.CENTER,
          spacing: { before: 30, after: 30 },
          children: [new TextRun({ text: name, size: 22, color: "374151", font: "Arial" })],
        })),
      ],
    },
    // PITCH SCRIPT PAGE
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
              new TextRun({ text: "  |  Elevator Pitch  |  CARA Format", size: 18, color: GRAY, font: "Arial" }),
            ],
          })],
        }),
      },
      footers: {
        default: new Footer({
          children: [new Paragraph({
            alignment: AlignmentType.CENTER,
            children: [
              new TextRun({ text: "The Neuronavs  |  Tech4Good 2026  |  Page ", size: 16, color: GRAY, font: "Arial" }),
              new TextRun({ children: [PageNumber.CURRENT], size: 16, color: GRAY, font: "Arial" }),
            ],
          })],
        }),
      },
      children: [
        // Title
        new Paragraph({
          spacing: { before: 100, after: 80 },
          alignment: AlignmentType.CENTER,
          children: [new TextRun({ text: "ELEVATOR PITCH SCRIPT", bold: true, size: 32, color: BRAND_BLUE, font: "Arial" })],
        }),
        new Paragraph({
          spacing: { before: 0, after: 60 },
          alignment: AlignmentType.CENTER,
          children: [new TextRun({ text: "Total Duration: 1 minute (60 seconds)", size: 20, color: GRAY, font: "Arial" })],
        }),
        spacer(200),

        // HOOK
        ...sectionBlock("HOOK", "5 seconds", "What if you forgot how to make breakfast \u2014 every single morning?", "DC2626"),

        // CONTEXT
        ...sectionBlock("CONTEXT", "10 seconds", "For millions of adults with cognitive disabilities, daily tasks we take for granted \u2014 cooking, hygiene, medication \u2014 require constant supervision. Caregivers spend over 24 hours a week providing unpaid care.", BRAND_BLUE),

        // ACTION
        ...sectionBlock("ACTION", "10 seconds", "We created NeuroNav \u2014 an adaptive assistant that guides users through daily routines step by step, automatically adjusting difficulty in real-time with voice, haptics, and visual cues.", BRAND_TEAL),

        // RESULT
        ...sectionBlock("RESULT", "10 seconds", "Patients gain independence. Caregivers monitor remotely. Families stay connected. Our app detects when users get stuck and provides automatic help \u2014 no human intervention needed.", BRAND_GOLD),

        // LEARNING
        ...sectionBlock("LEARNING", "10 seconds", "We discovered that cognitive support must be personalized \u2014 not static. Our 5-level adaptive engine learns from each user, making tasks easier or harder based on their real performance.", "7C3AED"),

        // HARD DATA
        ...sectionBlock("HARD DATA", "15 seconds", "According to the WHO in 2024, 1.3 billion people live with significant disabilities \u2014 that\u2019s 16% of the world\u2019s population. Caregivers now spend 26 hours per week on unpaid care, according to Guardian Life 2023. And the assistive technology market will reach 41 billion dollars by 2033, per IMARC Group. NeuroNav sits right at this intersection.", "059669"),

        // PAGE BREAK
        new Paragraph({ children: [new PageBreak()] }),

        // SOURCES PAGE
        new Paragraph({
          spacing: { before: 100, after: 200 },
          alignment: AlignmentType.CENTER,
          children: [new TextRun({ text: "HARD DATA SOURCES", bold: true, size: 32, color: BRAND_BLUE, font: "Arial" })],
        }),
        spacer(100),

        // Source 1
        new Table({
          width: { size: 9360, type: WidthType.DXA },
          columnWidths: [2400, 6960],
          rows: [
            new TableRow({
              children: [
                new TableCell({
                  width: { size: 2400, type: WidthType.DXA },
                  borders: thinBorders,
                  shading: { fill: BRAND_BLUE, type: ShadingType.CLEAR },
                  margins: { top: 100, bottom: 100, left: 120, right: 120 },
                  verticalAlign: "center",
                  children: [new Paragraph({
                    alignment: AlignmentType.CENTER,
                    children: [new TextRun({ text: "STATISTIC", bold: true, size: 20, color: WHITE, font: "Arial" })],
                  })],
                }),
                new TableCell({
                  width: { size: 6960, type: WidthType.DXA },
                  borders: thinBorders,
                  shading: { fill: BRAND_BLUE, type: ShadingType.CLEAR },
                  margins: { top: 100, bottom: 100, left: 120, right: 120 },
                  children: [new Paragraph({
                    children: [new TextRun({ text: "SOURCE", bold: true, size: 20, color: WHITE, font: "Arial" })],
                  })],
                }),
              ],
            }),
            // Row 1
            new TableRow({
              children: [
                new TableCell({
                  width: { size: 2400, type: WidthType.DXA },
                  borders: thinBorders,
                  shading: { fill: LIGHT_GRAY, type: ShadingType.CLEAR },
                  margins: { top: 100, bottom: 100, left: 120, right: 120 },
                  children: [new Paragraph({
                    alignment: AlignmentType.CENTER,
                    children: [new TextRun({ text: "1.3 billion people (16%) live with significant disabilities", bold: true, size: 20, color: "1F2937", font: "Arial" })],
                  })],
                }),
                new TableCell({
                  width: { size: 6960, type: WidthType.DXA },
                  borders: thinBorders,
                  shading: { fill: LIGHT_GRAY, type: ShadingType.CLEAR },
                  margins: { top: 100, bottom: 100, left: 120, right: 120 },
                  children: [
                    new Paragraph({
                      children: [new TextRun({ text: "World Health Organization (WHO)", bold: true, size: 20, font: "Arial", color: "1F2937" })],
                    }),
                    new Paragraph({
                      spacing: { before: 40 },
                      children: [new TextRun({ text: "Global Report on Health Equity for Persons with Disabilities, 2024", size: 18, font: "Arial", color: GRAY })],
                    }),
                    new Paragraph({
                      spacing: { before: 40 },
                      children: [new TextRun({ text: "who.int/news-room/fact-sheets/detail/disability-and-health", size: 16, font: "Arial", color: BRAND_TEAL })],
                    }),
                  ],
                }),
              ],
            }),
            // Row 2
            new TableRow({
              children: [
                new TableCell({
                  width: { size: 2400, type: WidthType.DXA },
                  borders: thinBorders,
                  shading: { fill: WHITE, type: ShadingType.CLEAR },
                  margins: { top: 100, bottom: 100, left: 120, right: 120 },
                  children: [new Paragraph({
                    alignment: AlignmentType.CENTER,
                    children: [new TextRun({ text: "Caregivers spend 26 hours/week on unpaid care", bold: true, size: 20, color: "1F2937", font: "Arial" })],
                  })],
                }),
                new TableCell({
                  width: { size: 6960, type: WidthType.DXA },
                  borders: thinBorders,
                  shading: { fill: WHITE, type: ShadingType.CLEAR },
                  margins: { top: 100, bottom: 100, left: 120, right: 120 },
                  children: [
                    new Paragraph({
                      children: [new TextRun({ text: "Guardian Life", bold: true, size: 20, font: "Arial", color: "1F2937" })],
                    }),
                    new Paragraph({
                      spacing: { before: 40 },
                      children: [new TextRun({ text: "Caregiving in America 2023 Study", size: 18, font: "Arial", color: GRAY })],
                    }),
                    new Paragraph({
                      spacing: { before: 40 },
                      children: [new TextRun({ text: "guardianlife.com/reports/caregiving-in-america-2023", size: 16, font: "Arial", color: BRAND_TEAL })],
                    }),
                  ],
                }),
              ],
            }),
            // Row 3
            new TableRow({
              children: [
                new TableCell({
                  width: { size: 2400, type: WidthType.DXA },
                  borders: thinBorders,
                  shading: { fill: LIGHT_GRAY, type: ShadingType.CLEAR },
                  margins: { top: 100, bottom: 100, left: 120, right: 120 },
                  children: [new Paragraph({
                    alignment: AlignmentType.CENTER,
                    children: [new TextRun({ text: "AT market projected to reach $41B by 2033", bold: true, size: 20, color: "1F2937", font: "Arial" })],
                  })],
                }),
                new TableCell({
                  width: { size: 6960, type: WidthType.DXA },
                  borders: thinBorders,
                  shading: { fill: LIGHT_GRAY, type: ShadingType.CLEAR },
                  margins: { top: 100, bottom: 100, left: 120, right: 120 },
                  children: [
                    new Paragraph({
                      children: [new TextRun({ text: "IMARC Group", bold: true, size: 20, font: "Arial", color: "1F2937" })],
                    }),
                    new Paragraph({
                      spacing: { before: 40 },
                      children: [new TextRun({ text: "Assistive Technology Market Report, 2024", size: 18, font: "Arial", color: GRAY })],
                    }),
                    new Paragraph({
                      spacing: { before: 40 },
                      children: [new TextRun({ text: "imarcgroup.com/assistive-technology-market", size: 16, font: "Arial", color: BRAND_TEAL })],
                    }),
                  ],
                }),
              ],
            }),
            // Row 4
            new TableRow({
              children: [
                new TableCell({
                  width: { size: 2400, type: WidthType.DXA },
                  borders: thinBorders,
                  shading: { fill: WHITE, type: ShadingType.CLEAR },
                  margins: { top: 100, bottom: 100, left: 120, right: 120 },
                  children: [new Paragraph({
                    alignment: AlignmentType.CENTER,
                    children: [new TextRun({ text: "3+ billion people affected by neurological conditions", bold: true, size: 20, color: "1F2937", font: "Arial" })],
                  })],
                }),
                new TableCell({
                  width: { size: 6960, type: WidthType.DXA },
                  borders: thinBorders,
                  shading: { fill: WHITE, type: ShadingType.CLEAR },
                  margins: { top: 100, bottom: 100, left: 120, right: 120 },
                  children: [
                    new Paragraph({
                      children: [new TextRun({ text: "The Lancet Neurology / WHO", bold: true, size: 20, font: "Arial", color: "1F2937" })],
                    }),
                    new Paragraph({
                      spacing: { before: 40 },
                      children: [new TextRun({ text: "Global Burden of Neurological Conditions Study, March 2024", size: 18, font: "Arial", color: GRAY })],
                    }),
                    new Paragraph({
                      spacing: { before: 40 },
                      children: [new TextRun({ text: "who.int/news/item/14-03-2024-neurological-conditions", size: 16, font: "Arial", color: BRAND_TEAL })],
                    }),
                  ],
                }),
              ],
            }),
            // Row 5
            new TableRow({
              children: [
                new TableCell({
                  width: { size: 2400, type: WidthType.DXA },
                  borders: thinBorders,
                  shading: { fill: LIGHT_GRAY, type: ShadingType.CLEAR },
                  margins: { top: 100, bottom: 100, left: 120, right: 120 },
                  children: [new Paragraph({
                    alignment: AlignmentType.CENTER,
                    children: [new TextRun({ text: "53 million family caregivers in the U.S.", bold: true, size: 20, color: "1F2937", font: "Arial" })],
                  })],
                }),
                new TableCell({
                  width: { size: 6960, type: WidthType.DXA },
                  borders: thinBorders,
                  shading: { fill: LIGHT_GRAY, type: ShadingType.CLEAR },
                  margins: { top: 100, bottom: 100, left: 120, right: 120 },
                  children: [
                    new Paragraph({
                      children: [new TextRun({ text: "AARP & National Alliance for Caregiving", bold: true, size: 20, font: "Arial", color: "1F2937" })],
                    }),
                    new Paragraph({
                      spacing: { before: 40 },
                      children: [new TextRun({ text: "Caregiving in the U.S. Report, 2020 (updated 2024)", size: 18, font: "Arial", color: GRAY })],
                    }),
                    new Paragraph({
                      spacing: { before: 40 },
                      children: [new TextRun({ text: "aarp.org/caregiving", size: 16, font: "Arial", color: BRAND_TEAL })],
                    }),
                  ],
                }),
              ],
            }),
          ],
        }),

        spacer(300),

        // Tips section
        new Paragraph({
          spacing: { before: 200, after: 120 },
          border: { bottom: { style: BorderStyle.SINGLE, size: 2, color: BRAND_TEAL, space: 6 } },
          children: [new TextRun({ text: "DELIVERY TIPS", bold: true, size: 26, color: BRAND_BLUE, font: "Arial" })],
        }),
        new Paragraph({
          numbering: { reference: "bullets", level: 0 },
          spacing: { before: 80, after: 60 },
          children: [
            new TextRun({ text: "Hook: ", bold: true, size: 22, font: "Arial", color: "374151" }),
            new TextRun({ text: "Pause after the question. Let it sink in. Make eye contact.", size: 22, font: "Arial", color: "374151" }),
          ],
        }),
        new Paragraph({
          numbering: { reference: "bullets", level: 0 },
          spacing: { before: 60, after: 60 },
          children: [
            new TextRun({ text: "Context: ", bold: true, size: 22, font: "Arial", color: "374151" }),
            new TextRun({ text: "Speak with empathy. Slow down on the statistics.", size: 22, font: "Arial", color: "374151" }),
          ],
        }),
        new Paragraph({
          numbering: { reference: "bullets", level: 0 },
          spacing: { before: 60, after: 60 },
          children: [
            new TextRun({ text: "Action: ", bold: true, size: 22, font: "Arial", color: "374151" }),
            new TextRun({ text: "Show confidence. This is YOUR solution. Emphasize \"adaptive\" and \"real-time\".", size: 22, font: "Arial", color: "374151" }),
          ],
        }),
        new Paragraph({
          numbering: { reference: "bullets", level: 0 },
          spacing: { before: 60, after: 60 },
          children: [
            new TextRun({ text: "Result: ", bold: true, size: 22, font: "Arial", color: "374151" }),
            new TextRun({ text: "Use short, punchy sentences. Build momentum.", size: 22, font: "Arial", color: "374151" }),
          ],
        }),
        new Paragraph({
          numbering: { reference: "bullets", level: 0 },
          spacing: { before: 60, after: 60 },
          children: [
            new TextRun({ text: "Hard Data: ", bold: true, size: 22, font: "Arial", color: "374151" }),
            new TextRun({ text: "Always say the source name BEFORE the number. End strong with \"NeuroNav sits right at this intersection.\"", size: 22, font: "Arial", color: "374151" }),
          ],
        }),
        new Paragraph({
          numbering: { reference: "bullets", level: 0 },
          spacing: { before: 60, after: 60 },
          children: [
            new TextRun({ text: "Everyone speaks: ", bold: true, size: 22, font: "Arial", color: "DC2626" }),
            new TextRun({ text: "Split sections among all 5 team members. Suggested: Hook+Context (1), Action (2), Result (3), Learning (4), Hard Data (5).", size: 22, font: "Arial", color: "374151" }),
          ],
        }),

        // Closing
        spacer(400),
        new Paragraph({
          alignment: AlignmentType.CENTER,
          border: { top: { style: BorderStyle.SINGLE, size: 3, color: BRAND_TEAL, space: 12 } },
          spacing: { before: 300, after: 80 },
          children: [new TextRun({ text: "NeuroNav", bold: true, size: 36, color: BRAND_BLUE, font: "Arial" })],
        }),
        new Paragraph({
          alignment: AlignmentType.CENTER,
          spacing: { before: 60, after: 60 },
          children: [new TextRun({ text: "Empowering independence through adaptive technology", italics: true, size: 22, color: BRAND_TEAL, font: "Arial" })],
        }),
      ],
    },
  ],
});

Packer.toBuffer(doc).then(buffer => {
  fs.writeFileSync("/Users/salvador/Desktop/Apps Kirks/Proyecto2/NeuroNav_Elevator_Pitch.docx", buffer);
  console.log("Elevator Pitch saved to: /Users/salvador/Desktop/Apps Kirks/Proyecto2/NeuroNav_Elevator_Pitch.docx");
});
