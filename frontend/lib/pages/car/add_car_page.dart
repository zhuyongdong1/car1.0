import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import '../../models/car.dart';
import '../../models/customer.dart';
import '../../providers/car_provider.dart';
import '../../providers/customer_provider.dart';

class AddCarPage extends StatefulWidget {
  const AddCarPage({super.key});

  @override
  State<AddCarPage> createState() => _AddCarPageState();
}

class _AddCarPageState extends State<AddCarPage> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isLoading = false;
  List<Customer> _customers = [];

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    try {
      final customerProvider = context.read<CustomerProvider>();
      await customerProvider.fetchCustomers();
      setState(() {
        _customers = customerProvider.customers;
      });
    } catch (e) {
      // 加载客户列表失败，继续执行不影响用户体验
      debugPrint('Failed to load customers: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('添加车辆'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: FormBuilder(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '车辆基本信息',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                      ),
                      const SizedBox(height: 16),
                      // 客户选择
                      FormBuilderDropdown<int>(
                        name: 'customerId',
                        decoration: const InputDecoration(
                          labelText: '关联客户',
                          hintText: '选择车辆所属客户（可选）',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        items: _customers
                            .map((customer) => DropdownMenuItem(
                                  value: customer.id,
                                  child: Text(
                                    '${customer.name} - ${customer.phone}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 16),
                      FormBuilderTextField(
                        name: 'plateNumber',
                        decoration: const InputDecoration(
                          labelText: '车牌号码 *',
                          hintText: '例如：京A12345',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.directions_car),
                        ),
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.required(errorText: '请输入车牌号码'),
                          FormBuilderValidators.minLength(5,
                              errorText: '车牌号码至少5位'),
                        ]),
                        textCapitalization: TextCapitalization.characters,
                      ),
                      const SizedBox(height: 16),
                      FormBuilderTextField(
                        name: 'vin',
                        decoration: const InputDecoration(
                          labelText: '车架号 *',
                          hintText: '17位车架号',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.confirmation_number),
                        ),
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.required(errorText: '请输入车架号'),
                          FormBuilderValidators.minLength(17,
                              errorText: '车架号必须是17位'),
                          FormBuilderValidators.maxLength(17,
                              errorText: '车架号必须是17位'),
                        ]),
                        textCapitalization: TextCapitalization.characters,
                        maxLength: 17,
                      ),
                      const SizedBox(height: 16),
                      FormBuilderTextField(
                        name: 'brand',
                        decoration: const InputDecoration(
                          labelText: '品牌',
                          hintText: '例如：大众、丰田',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.branding_watermark),
                        ),
                      ),
                      const SizedBox(height: 16),
                      FormBuilderTextField(
                        name: 'model',
                        decoration: const InputDecoration(
                          labelText: '型号',
                          hintText: '例如：帕萨特、凯美瑞',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.model_training),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: FormBuilderTextField(
                              name: 'year',
                              decoration: const InputDecoration(
                                labelText: '年份',
                                hintText: '例如：2020',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.calendar_today),
                              ),
                              keyboardType: TextInputType.number,
                              validator: FormBuilderValidators.compose([
                                FormBuilderValidators.integer(
                                    errorText: '请输入有效年份'),
                                FormBuilderValidators.min(1900,
                                    errorText: '年份不能小于1900'),
                                FormBuilderValidators.max(
                                    DateTime.now().year + 1,
                                    errorText:
                                        '年份不能大于${DateTime.now().year + 1}'),
                              ]),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: FormBuilderTextField(
                              name: 'color',
                              decoration: const InputDecoration(
                                labelText: '颜色',
                                hintText: '例如：白色、黑色',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.palette),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isLoading ? null : () => Navigator.pop(context),
                      child: const Text('取消'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('保存'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        final formData = _formKey.currentState!.value;

        final car = Car(
          plateNumber: formData['plateNumber'],
          vin: formData['vin'],
          brand: formData['brand'],
          model: formData['model'],
          year:
              formData['year'] != null ? int.tryParse(formData['year']) : null,
          color: formData['color'],
          customerId: formData['customerId'],
        );

        final carProvider = Provider.of<CarProvider>(context, listen: false);
        final success = await carProvider.addCar(car);

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('车辆添加成功'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(carProvider.error ?? '添加车辆失败'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('添加车辆失败: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }
}
