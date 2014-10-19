module UsableDynamo
  module ClientMethods
    module Callback

      # Callback methods, the simple way.
      def after_find(method, options = {})
        add_callback(:after_find, method, options)
      end

      def before_validation(method, options = {})
        add_callback(:before_validation, method, options)
      end

      def after_validation(method, options = {})
        add_callback(:after_validation, method, options)
      end

      def before_save(method, options = {})
        add_callback(:before_save, method, options)
      end

      def before_create(method, options = {})
        add_callback(:before_create, method, options)
      end

      def before_update(method, options = {})
        add_callback(:before_update, method, options)
      end

      def before_destroy(method, options = {})
        add_callback(:before_destroy, method, options)
      end

      def after_save(method, options = {})
        add_callback(:after_save, method, options)
      end

      def after_create(method, options = {})
        add_callback(:after_create, method, options)
      end

      def after_update(method, options = {})
        add_callback(:after_update, method, options)
      end

      def after_destroy(method, options = {})
        add_callback(:after_destroy, method, options)
      end

      private

      def add_callback(callback_type, method, options = {})
        callbacks[callback_type] ||= []
        callbacks[callback_type] << UsableDynamo::Callback.new(method, options)
      end

   	end
  end
end