require "csv"

class ContactImportsController < ApplicationController
  def create
    rows =
      if params[:sample].present?
        Contacts::Import.sample_batch(count: params.fetch(:count, 25).to_i.clamp(5, 100))
      else
        parse_csv(params[:csv].to_s)
      end

    if rows.blank?
      redirect_to root_path, alert: "Nothing to import. Paste CSV rows or import a sample batch."
      return
    end

    result = Contacts::Import.call(rows: rows, source: params[:sample].present? ? "hubspot" : "import")
    notice = "Imported #{result.created} contacts"
    notice += " (#{result.skipped} skipped)" if result.skipped.positive?
    notice += ". #{result.pending_count} waiting to be allocated."
    redirect_to root_path, notice: notice
  end

  private

  def parse_csv(text)
    lines = text.to_s.strip.split(/\r?\n/).map(&:strip).reject(&:blank?)
    return [] if lines.empty?

    header = lines.first.downcase
    has_header = header.include?("email")
    data_lines = has_header ? lines.drop(1) : lines
    headers = has_header ? CSV.parse_line(lines.first).map { |h| h.to_s.strip.downcase } : nil

    data_lines.filter_map do |line|
      cols = CSV.parse_line(line)
      next if cols.blank?

      if headers
        row = headers.zip(cols).to_h
        {
          email: row["email"],
          first_name: row["first_name"] || row["first"],
          last_name: row["last_name"] || row["last"],
          country: row["country"],
          persona: row["persona"]
        }
      else
        {
          email: cols[0],
          first_name: cols[1].presence || "New",
          last_name: cols[2].presence || "Contact",
          country: cols[3],
          persona: cols[4]
        }
      end
    end
  rescue CSV::MalformedCSVError
    []
  end
end
