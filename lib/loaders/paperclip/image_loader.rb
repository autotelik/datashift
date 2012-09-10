# Copyright:: (c) Autotelik Media Ltd 2012
# Author ::   Tom Statter
# Date ::     June 2012
# License::   MIT. Free, Open Source.
#
# => Provides facilities for bulk uploading/exporting attachments provided by PaperClip 
# gem
require 'loader_base'

module DataShift

  module ImageLoading
 
    include DataShift::Paperclip
    
    # Get all image files (based on file extensions) from supplied path.
    # Options : 
    #     :glob : The glob to use to find files
    # =>  :recursive : Descend tree looking for files rather than just supplied path
    
    def self.get_files(path, options = {})
      glob = options[:glob] ? options[:glob] : image_magik_glob
      glob = (options['recursive'] || options[:recursive])  ? "**/#{glob}" : glob
      
      Dir.glob("#{path}/#{glob}", File::FNM_CASEFOLD)
    end
  
    
    # Note the paperclip attachment model defines the storage path via something like :
    # => :path => ":rails_root/public/blah/blahs/:id/:style/:basename.:extension"
    # Options 
    #   has_attached_file_name : Paperclip attachment name defined with macro 'has_attached_file :name'  e.g has_attached_file :avatar
    #
    def create_image(klass, attachment_path, viewable_record = nil, options = {})
       
      has_attached_file = options[:has_attached_file_name] || :attachment
      
      alt = if(options[:alt])
        options[:alt]
      else
        (viewable_record and viewable_record.respond_to? :name) ? viewable_record.name : ""
      end
    
      position = (viewable_record and viewable_record.respond_to?(:images)) ? viewable_record.images.length : 0
          
      file = get_file(attachment_path)

      begin
        
        image = klass.new( 
          {has_attached_file.to_sym => file, :viewable => viewable_record, :alt => alt, :position => position},
          :without_protection => true
        )  
        
        #image.attachment.reprocess!  not sure this is required anymore
        
        puts image.save ? "Success: Created Image: #{image.id} : #{image.attachment_file_name}" : "ERROR : Problem saving to DB Image: #{image.inspect}"
      rescue => e
        puts "PaperClip error - Problem creating an Image from : #{attachment_path}"
        puts e.inspect, e.backtrace
      end
    end
    
    # Set of file extensions ImageMagik can process so default glob
    # we use to find image files within directories
    def self.image_magik_glob
      @im_glob ||= %w{*.3FR *.AAI *.AI *.ART *.ARW  *.AVI *.AVS *.BGR *.BGRA
                  *.BIE *.BMP *.BMP2  *.BMP3  *.BRF *.CAL *.CALS *.CANVAS
                  *.CIN *.CIP *.CLIP *.CMYK *.CMYKA *.CR2 *.CRW *.CUR *.CUT *.DCM *.DCR *.DCX
                  *.DDS *.DFONT *.DJVU *.DNG  *.DOT *.DPS *.DPX
                  *.EMF *.EPDF  *.EPI *.EPS *.EPS2 *.EPS3  *.EPSF *.EPSI
                  *.EPT *.EPT2 *.EPT3 *.ERF *.EXR *.FITS *.FPX  *.FTS *.G3 *.GIF *.GIF87
                  *.GRAY *.HALD  *.HDR *.HRZ  *.ICB *.ICO *.ICON *.IPL
                  *.ISOBRL *.J2C *.JBG  *.JBIG *.JNG *.JP2 *.JPC *.JPEG *.JPG *.JPX  *.K25 *.KDC
                  *.LABEL *.M2V  *.M4V  *.MAC *.MAP  *.MAT *.MATTE *.MIFF *.MNG  *.MONO
                  *.MOV *.MP4 *.MPC *.MPEG *.MPG *.MRW *.MSL *.MSVG *.MTV *.MVG *.NEF *.ORF *.OTB *.OTF *.PAL *.PALM
                  *.PAM *.PBM  *.PCD *.PCDS *.PCL *.PCT *.PCX *.PDB *.PDF *.PDFA  *.PEF
                  *.PES *.PFA *.PFB *.PFM *.PGM  *.PGX *.PICON *.PICT *.PIX *.PJPEG *.PLASMA
                  *.PNG *.PNG24  *.PNG32 *.PNG8 *.PNM *.PPM *.PS *.PS2 *.PS3 *.PSB *.PSD *.PTIF *.PWP *.RAF *.RAS *.RGB
                  *.RGBA *.RGBO *.RLA *.RLE *.SCR *.SCT *.SFW *.SGI *.SR2 *.SRF
                  *.SUN *.SVG *.SVGZ *.TGA *.TIFF *.TIFF64 *.TILE *.TIM *.TTC *.TTF *.UBRL *.UIL *.UYVY *.VDA  *.VICAR
                  *.VID *.VIFF  *.VST *.WBMP *.WEBP  *.WMF *.WMV *.WMZ *.WPG  *.X3F
                  *.XBM *.XC *.XCF *.XPM *.XPS *.XV *.XWD *.YCbCr *.YCbCrA *.YUV
      }
      "{#{@im_glob.join(',')}}"
    end
  end
      
end
