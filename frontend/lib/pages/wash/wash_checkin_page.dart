import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import '../../providers/wash_provider.dart';

class WashCheckinPage extends StatefulWidget {
  final int? carId;
  final String? plateNumber;

  const WashCheckinPage({super.key, this.carId, this.plateNumber});

  @override
  State<WashCheckinPage> createState() => _WashCheckinPageState();
}

class _WashCheckinPageState extends State<WashCheckinPage> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('洗车打卡'),
        backgroundColor: Colors.blue,
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
                      Row(
                        children: [
                          const Icon(Icons.local_car_wash, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            '洗车打卡',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (widget.plateNumber == null)
                        FormBuilderTextField(
                          name: 'plateNumber',
                          decoration: const InputDecoration(
                            labelText: '车牌号码 *',
                            hintText: '例如：京A12345',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.directions_car),
                          ),
                          validator: FormBuilderValidators.compose([
                            FormBuilderValidators.required(
                                errorText: '请输入车牌号码'),
                          ]),
                          textCapitalization: TextCapitalization.characters,
                        ),
                      if (widget.plateNumber == null)
                        const SizedBox(height: 16),
                      if (widget.plateNumber != null)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border:
                                Border.all(color: Colors.blue.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.directions_car, color: Colors.blue),
                              const SizedBox(width: 12),
                              Text(
                                '车牌号码: ${widget.plateNumber}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (widget.plateNumber != null)
                        const SizedBox(height: 16),
                      FormBuilderDropdown<String>(
                        name: 'washType',
                        decoration: const InputDecoration(
                          labelText: '洗车类型 *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category),
                        ),
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.required(errorText: '请选择洗车类型'),
                        ]),
                        items: const [
                          DropdownMenuItem(value: 'basic', child: Text('基础洗车')),
                          DropdownMenuItem(
                              value: 'premium', child: Text('精洗服务')),
                          DropdownMenuItem(
                              value: 'interior', child: Text('内饰清洁')),
                          DropdownMenuItem(value: 'wax', child: Text('打蜡护理')),
                          DropdownMenuItem(
                              value: 'detail', child: Text('精细美容')),
                          DropdownMenuItem(
                              value: 'engine', child: Text('发动机清洗')),
                          DropdownMenuItem(value: 'self', child: Text('自助洗车')),
                        ],
                        initialValue: 'basic',
                      ),
                      const SizedBox(height: 16),
                      FormBuilderTextField(
                        name: 'price',
                        decoration: const InputDecoration(
                          labelText: '洗车费用 *',
                          hintText: '例如：30.00',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.attach_money),
                          suffixText: '元',
                        ),
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.required(errorText: '请输入洗车费用'),
                          FormBuilderValidators.numeric(errorText: '请输入有效金额'),
                          FormBuilderValidators.min(0, errorText: '费用不能为负数'),
                        ]),
                        keyboardType: TextInputType.number,
                        initialValue: '30',
                      ),
                      const SizedBox(height: 16),
                      FormBuilderTextField(
                        name: 'location',
                        decoration: const InputDecoration(
                          labelText: '洗车地点',
                          hintText: '例如：XX洗车店',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on),
                        ),
                      ),
                      const SizedBox(height: 16),
                      FormBuilderTextField(
                        name: 'notes',
                        decoration: const InputDecoration(
                          labelText: '备注',
                          hintText: '其他说明信息',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.note),
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, color: Colors.green),
                    const SizedBox(width: 12),
                    Text(
                      '洗车时间: ${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')} ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
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
                      onPressed: _isLoading ? null : _submitCheckin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
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
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle),
                                SizedBox(width: 8),
                                Text('确认打卡', style: TextStyle(fontSize: 16)),
                              ],
                            ),
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

  Future<void> _submitCheckin() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        final formData = _formKey.currentState!.value;
        final plateNumber = widget.plateNumber ?? formData['plateNumber'];

        final washProvider = Provider.of<WashProvider>(context, listen: false);
        final success = await washProvider.quickWashCheckIn(
          plateNumber,
          washType: formData['washType'] ?? 'basic',
          price: double.parse(formData['price'] ?? '0'),
          location: formData['location'],
        );

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('洗车打卡成功'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(washProvider.error ?? '洗车打卡失败'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('洗车打卡失败: ${e.toString()}'),
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
