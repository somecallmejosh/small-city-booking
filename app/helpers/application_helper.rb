module ApplicationHelper
  def hour_options
    (0..23).map do |h|
      label = Time.zone.local(2000, 1, 1, h).strftime("%-I:%M %p")
      [ label, h ]
    end
  end

  # Renders a face-cropped avatar image or a letter fallback.
  # Uses Cloudinary face-detection crop when Cloudinary is active; falls back to
  # a plain Active Storage URL otherwise (e.g. local disk in development/test).
  def avatar_tag(user, size: 32, css_class: "rounded-full")
    if user.avatar.attached?
      if ActiveStorage::Blob.service.class.name == "ActiveStorage::Service::CloudinaryService"
        cl_image_tag(user.avatar.key,
          width: size, height: size,
          crop: "fill", gravity: "face",
          radius: "max", fetch_format: "auto", quality: "auto",
          class: "#{css_class} object-cover",
          style: "width:#{size}px;height:#{size}px;flex-shrink:0;",
          alt: user.name.presence || "Avatar")
      else
        image_tag(rails_blob_url(user.avatar),
          class: "#{css_class} object-cover",
          style: "width:#{size}px;height:#{size}px;flex-shrink:0;",
          alt: user.name.presence || "Avatar")
      end
    else
      initial = (user.name.presence || user.email_address).first.upcase
      content_tag(:span, initial,
        class: "#{css_class} inline-flex items-center justify-center bg-stone-200 text-xs font-semibold text-stone-700",
        style: "width:#{size}px;height:#{size}px;flex-shrink:0;")
    end
  end
end
