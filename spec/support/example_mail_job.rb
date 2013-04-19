class ExampleMailJob
  def set(to, subject, body)
    @to = to
    @subject = subject
    @body = body
    self
  end

  def work
    send_mail(@to, @subject, @body)
  end

  private
  def send_mail(to, subject, body)
    # some hard e-Mail sending work
  end
end
